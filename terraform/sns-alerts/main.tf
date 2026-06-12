# Terraform configuration is managed manually in the same style as fluentbit-opensearch.
# Configure the backend with -backend-config at init time before applying.

locals {
  alert_name            = "${var.prefix}-gen3-alerts"
  gen3_domain           = trimsuffix(var.gen3_domain, ".")
  teams_count           = var.enable_teams_webhook ? 1 : 0
  teams_lambda_name     = "${var.prefix}-alerts-teams-forwarder"
  teams_secret_name     = "${var.prefix}/alerts/teams-webhook"
  teams_queue_name      = "${var.prefix}-alerts-teams"
  teams_dlq_name        = "${var.prefix}-alerts-teams-dlq"
  health_check_name     = "${var.prefix}-gen3-portal-health"
  health_check_alarm    = "${var.prefix}-gen3-portal-unhealthy"
  lambda_log_group_name = "/aws/lambda/${local.teams_lambda_name}"

  common_tags = {
    Environment = var.prefix
    Terraform   = "true"
  }
}

# ==============================================================================
# SNS ALERT TOPIC
# ==============================================================================

resource "aws_sns_topic" "alerts" {
  name         = local.alert_name
  display_name = "${var.prefix} Gen3 alerts"

  tags = merge(local.common_tags, {
    Name = local.alert_name
  })
}

# ==============================================================================
# ROUTE 53 HEALTH CHECK AND CLOUDWATCH ALARM
# ==============================================================================

resource "aws_route53_health_check" "gen3_portal" {
  fqdn              = local.gen3_domain
  port              = var.health_check_port
  type              = "HTTPS"
  resource_path     = var.health_check_path
  request_interval  = var.health_check_request_interval
  failure_threshold = var.health_check_failure_threshold
  measure_latency   = true
  enable_sni        = true

  tags = merge(local.common_tags, {
    Name = local.health_check_name
  })
}

resource "aws_cloudwatch_metric_alarm" "gen3_portal_unhealthy" {
  alarm_name          = local.health_check_alarm
  alarm_description   = "Alerts when the Gen3 portal health check for https://${local.gen3_domain}${var.health_check_path} fails."
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  comparison_operator = "LessThanThreshold"
  statistic           = "Minimum"
  threshold           = 1
  period              = 60
  evaluation_periods  = 1
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.gen3_portal.id
  }

  tags = merge(local.common_tags, {
    Name = local.health_check_alarm
  })
}

# ==============================================================================
# OPTIONAL TEAMS WEBHOOK SECRET
# ==============================================================================

resource "aws_secretsmanager_secret" "teams_webhook" {
  count = local.teams_count

  name                    = local.teams_secret_name
  description             = "Teams webhook URL for ${var.prefix} Gen3 alerts"
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = local.teams_secret_name
  })
}

resource "aws_secretsmanager_secret_version" "teams_webhook" {
  count = local.teams_count

  secret_id                = aws_secretsmanager_secret.teams_webhook[0].id
  secret_string_wo         = var.teams_webhook_url
  secret_string_wo_version = var.teams_webhook_secret_version
}

# ==============================================================================
# OPTIONAL TEAMS SQS QUEUE
# ==============================================================================

resource "aws_sqs_queue" "teams_dlq" {
  count = local.teams_count

  name                      = local.teams_dlq_name
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

  tags = merge(local.common_tags, {
    Name = local.teams_dlq_name
  })
}

resource "aws_sqs_queue" "teams" {
  count = local.teams_count

  name                       = local.teams_queue_name
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.teams_dlq[0].arn
    maxReceiveCount     = 5
  })

  tags = merge(local.common_tags, {
    Name = local.teams_queue_name
  })
}

data "aws_iam_policy_document" "teams_queue" {
  count = local.teams_count

  statement {
    sid     = "AllowSnsToSendAlerts"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    resources = [aws_sqs_queue.teams[0].arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.alerts.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "teams" {
  count = local.teams_count

  queue_url = aws_sqs_queue.teams[0].id
  policy    = data.aws_iam_policy_document.teams_queue[0].json
}

resource "aws_sns_topic_subscription" "teams_queue" {
  count = local.teams_count

  topic_arn            = aws_sns_topic.alerts.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.teams[0].arn
  raw_message_delivery = true

  depends_on = [aws_sqs_queue_policy.teams]
}

# ==============================================================================
# OPTIONAL TEAMS LAMBDA
# ==============================================================================

data "archive_file" "teams_forwarder" {
  count = local.teams_count

  type        = "zip"
  source_file = "${path.module}/lambda/teams_forwarder.py"
  output_path = "${path.module}/.terraform/teams_forwarder.zip"
}

data "aws_iam_policy_document" "teams_lambda_assume_role" {
  count = local.teams_count

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "teams_lambda" {
  count = local.teams_count

  name               = local.teams_lambda_name
  assume_role_policy = data.aws_iam_policy_document.teams_lambda_assume_role[0].json

  tags = merge(local.common_tags, {
    Name = local.teams_lambda_name
  })
}

data "aws_iam_policy_document" "teams_lambda" {
  count = local.teams_count

  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.teams_lambda[0].arn}:*",
    ]
  }

  statement {
    sid    = "ReadWebhookSecret"
    effect = "Allow"

    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.teams_webhook[0].arn]
  }

  statement {
    sid    = "ProcessTeamsQueue"
    effect = "Allow"

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]

    resources = [aws_sqs_queue.teams[0].arn]
  }
}

resource "aws_iam_role_policy" "teams_lambda" {
  count = local.teams_count

  name   = "${local.teams_lambda_name}-policy"
  role   = aws_iam_role.teams_lambda[0].id
  policy = data.aws_iam_policy_document.teams_lambda[0].json
}

resource "aws_cloudwatch_log_group" "teams_lambda" {
  count = local.teams_count

  name              = local.lambda_log_group_name
  retention_in_days = var.teams_lambda_log_retention_days

  tags = merge(local.common_tags, {
    Name = local.lambda_log_group_name
  })
}

resource "aws_lambda_function" "teams_forwarder" {
  count = local.teams_count

  function_name    = local.teams_lambda_name
  description      = "Forwards ${var.prefix} Gen3 alert notifications from SNS/SQS to a Teams webhook"
  role             = aws_iam_role.teams_lambda[0].arn
  handler          = "teams_forwarder.handler"
  runtime          = "python3.12"
  timeout          = var.teams_lambda_timeout_seconds
  filename         = data.archive_file.teams_forwarder[0].output_path
  source_code_hash = data.archive_file.teams_forwarder[0].output_base64sha256

  environment {
    variables = {
      GEN3_DOMAIN              = local.gen3_domain
      TEAMS_WEBHOOK_SECRET_ARN = aws_secretsmanager_secret.teams_webhook[0].arn
    }
  }

  tags = merge(local.common_tags, {
    Name = local.teams_lambda_name
  })

  depends_on = [
    aws_cloudwatch_log_group.teams_lambda,
    aws_iam_role_policy.teams_lambda,
  ]
}

resource "aws_lambda_event_source_mapping" "teams_queue" {
  count = local.teams_count

  event_source_arn = aws_sqs_queue.teams[0].arn
  function_name    = aws_lambda_function.teams_forwarder[0].arn
  batch_size       = 1
  enabled          = true
}

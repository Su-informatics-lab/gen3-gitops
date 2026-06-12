output "sns_topic_arn" {
  description = "ARN of the SNS topic that receives Gen3 alerts."
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic that receives Gen3 alerts."
  value       = aws_sns_topic.alerts.name
}

output "route53_health_check_id" {
  description = "ID of the Route 53 health check for the Gen3 portal."
  value       = aws_route53_health_check.gen3_portal.id
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm that publishes failed health checks to SNS."
  value       = aws_cloudwatch_metric_alarm.gen3_portal_unhealthy.alarm_name
}

output "cloudwatch_alarm_arn" {
  description = "ARN of the CloudWatch alarm that publishes failed health checks to SNS."
  value       = aws_cloudwatch_metric_alarm.gen3_portal_unhealthy.arn
}

output "teams_queue_url" {
  description = "URL of the Teams forwarding SQS queue when Teams delivery is enabled."
  value       = try(aws_sqs_queue.teams[0].url, null)
}

output "teams_queue_arn" {
  description = "ARN of the Teams forwarding SQS queue when Teams delivery is enabled."
  value       = try(aws_sqs_queue.teams[0].arn, null)
}

output "teams_dead_letter_queue_arn" {
  description = "ARN of the Teams forwarding dead-letter queue when Teams delivery is enabled."
  value       = try(aws_sqs_queue.teams_dlq[0].arn, null)
}

output "teams_webhook_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the Teams webhook URL when Teams delivery is enabled."
  value       = try(aws_secretsmanager_secret.teams_webhook[0].arn, null)
}

output "teams_lambda_function_name" {
  description = "Name of the Teams forwarding Lambda when Teams delivery is enabled."
  value       = try(aws_lambda_function.teams_forwarder[0].function_name, null)
}

output "teams_lambda_function_arn" {
  description = "ARN of the Teams forwarding Lambda when Teams delivery is enabled."
  value       = try(aws_lambda_function.teams_forwarder[0].arn, null)
}

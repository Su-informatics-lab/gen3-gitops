# Terraform configuration is managed by Terragrunt when used in a commons environment.
# Can also be run standalone: configure provider + backend before applying.

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# Requires an IAM OIDC provider to already be associated with the EKS cluster.
# Create one via: eksctl utils associate-iam-oidc-provider --cluster <name> --approve
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ==============================================================================
# IAM POLICIES
# ==============================================================================

resource "aws_iam_policy" "fluentbit_cloudwatch" {
  name        = "${var.prefix}-fluentbit-cloudwatch"
  description = "Allows Fluent Bit to write logs to CloudWatch for the ${var.prefix} log group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FluentBitCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}",
          "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*",
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.prefix}-fluentbit-cloudwatch"
    Environment = var.prefix
    Terraform   = "true"
  }
}

resource "aws_iam_policy" "fluentbit_opensearch" {
  name        = "${var.prefix}-fluentbit-opensearch"
  description = "Allows Fluent Bit to write to the ${var.opensearch_domain_name} OpenSearch domain"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "FluentBitOpenSearchWrite"
        Effect = "Allow"
        Action = "es:ESHttp*"
        Resource = "arn:${data.aws_partition.current.partition}:es:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/*"
      }
    ]
  })

  tags = {
    Name        = "${var.prefix}-fluentbit-opensearch"
    Environment = var.prefix
    Terraform   = "true"
  }
}

# ==============================================================================
# IRSA ROLE
# ==============================================================================

module "fluentbit_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name = "${var.prefix}-fluentbit-sa"
  role_path = "/gen3-service/"

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["${var.fluentbit_namespace}:${var.fluentbit_service_account}"]
    }
  }

  role_policy_arns = {
    cloudwatch = aws_iam_policy.fluentbit_cloudwatch.arn
    opensearch = aws_iam_policy.fluentbit_opensearch.arn
  }

  tags = {
    Name        = "${var.prefix}-fluentbit-sa"
    Environment = var.prefix
    Terraform   = "true"
  }
}

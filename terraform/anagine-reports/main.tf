data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_s3_bucket" "reports" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.prefix
    Terraform   = "true"
  }
}

resource "aws_s3_bucket_public_access_block" "reports" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "reports" {
  bucket = aws_s3_bucket.reports.id

  rule {
    id     = "expire-reports-after-one-day"
    status = "Enabled"

    filter {
      prefix = "reports/"
    }

    expiration {
      days = 1
    }
  }
}

resource "aws_iam_policy" "reports" {
  name        = "${var.prefix}-anagine-reports"
  description = "Allows Anagine to read and write generated reports in ${var.bucket_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReportObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = "${aws_s3_bucket.reports.arn}/reports/*"
      },
      {
        Sid      = "ReportPrefixListing"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.reports.arn
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "reports/",
              "reports/*",
            ]
          }
        }
      },
    ]
  })

  tags = {
    Name        = "${var.prefix}-anagine-reports"
    Environment = var.prefix
    Terraform   = "true"
  }
}

module "anagine_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name = "${var.prefix}-anagine-sa"
  role_path = "/gen3-service/"

  oidc_providers = {
    main = {
      provider_arn               = data.aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["${var.anagine_namespace}:${var.anagine_service_account}"]
    }
  }

  role_policy_arns = {
    reports = aws_iam_policy.reports.arn
  }

  tags = {
    Name        = "${var.prefix}-anagine-sa"
    Environment = var.prefix
    Terraform   = "true"
  }
}

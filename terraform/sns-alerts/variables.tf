variable "aws_region" {
  description = "AWS region. Route 53 health check CloudWatch metrics are emitted in us-east-1."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication. Leave empty to use the default credential chain."
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Environment name prefix used to name resources (e.g. ardac1prd)."
  type        = string
}

variable "gen3_domain" {
  description = "Gen3 portal domain to monitor, without protocol (e.g. portal.ardac.org)."
  type        = string

  validation {
    condition     = !can(regex("^https?://", var.gen3_domain))
    error_message = "gen3_domain must be a hostname only, without http:// or https://."
  }
}

variable "health_check_path" {
  description = "HTTPS path to request on the Gen3 portal domain."
  type        = string
  default     = "/"

  validation {
    condition     = can(regex("^/", var.health_check_path))
    error_message = "health_check_path must start with /."
  }
}

variable "health_check_port" {
  description = "HTTPS port for the Route 53 health check."
  type        = number
  default     = 443

  validation {
    condition     = var.health_check_port >= 1 && var.health_check_port <= 65535
    error_message = "health_check_port must be between 1 and 65535."
  }
}

variable "health_check_request_interval" {
  description = "Number of seconds between Route 53 health check requests. Route 53 supports 10 or 30."
  type        = number
  default     = 30

  validation {
    condition     = contains([10, 30], var.health_check_request_interval)
    error_message = "health_check_request_interval must be 10 or 30."
  }
}

variable "health_check_failure_threshold" {
  description = "Number of consecutive failed health check requests before Route 53 considers the endpoint unhealthy."
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_failure_threshold >= 1 && var.health_check_failure_threshold <= 10
    error_message = "health_check_failure_threshold must be between 1 and 10."
  }
}

variable "enable_teams_webhook" {
  description = "Whether to create the SQS, Lambda, and Secrets Manager resources that forward SNS alerts to a Teams webhook."
  type        = bool
  default     = false
}

variable "teams_webhook_url" {
  description = "Teams webhook URL. Required when enable_teams_webhook is true. This value is ephemeral and is not written to Terraform state or plan files."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
  ephemeral   = true
}

variable "teams_webhook_secret_version" {
  description = "Monotonic version marker for the write-only Teams webhook secret value. Increment when rotating teams_webhook_url."
  type        = number
  default     = 1

  validation {
    condition     = var.teams_webhook_secret_version >= 1
    error_message = "teams_webhook_secret_version must be greater than or equal to 1."
  }
}

variable "teams_lambda_log_retention_days" {
  description = "Number of days to retain CloudWatch logs for the Teams forwarder Lambda."
  type        = number
  default     = 30
}

variable "teams_lambda_timeout_seconds" {
  description = "Timeout in seconds for the Teams forwarder Lambda."
  type        = number
  default     = 10

  validation {
    condition     = var.teams_lambda_timeout_seconds >= 1 && var.teams_lambda_timeout_seconds <= 30
    error_message = "teams_lambda_timeout_seconds must be between 1 and 30."
  }
}

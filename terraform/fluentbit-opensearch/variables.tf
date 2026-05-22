variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication. Leave empty to use the default credential chain (e.g. IAM role, environment variables)."
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Environment name prefix used to name all resources (e.g. ardac1prd)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name. Used to look up the OIDC provider for IRSA trust. Requires an IAM OIDC provider to already be associated with the cluster."
  type        = string
}

variable "opensearch_domain_name" {
  description = "Name of the AWS OpenSearch Service domain (not the full endpoint hostname — just the domain name portion, e.g. ardac1prd-gen3-metadata)"
  type        = string
}

variable "log_group_name" {
  description = "CloudWatch log group name that Fluent Bit writes to (e.g. ardac1prd)"
  type        = string
}

variable "fluentbit_namespace" {
  description = "Kubernetes namespace where the Fluent Bit service account lives"
  type        = string
  default     = "kube-system"
}

variable "fluentbit_service_account" {
  description = "Name of the Fluent Bit Kubernetes service account. Must match serviceAccount.name in the Helm values (default is 'fluent-bit')."
  type        = string
  default     = "fluent-bit"
}

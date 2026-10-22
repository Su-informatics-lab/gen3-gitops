variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use for authentication. Leave empty to use the default credential chain."
  type        = string
  default     = ""
}

variable "prefix" {
  description = "Environment name prefix used to name the Anagine IRSA role"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name used to look up the IAM OIDC provider for IRSA"
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for generated Anagine reports"
  type        = string
}

variable "anagine_namespace" {
  description = "Kubernetes namespace containing the Anagine service account"
  type        = string
  default     = "default"
}

variable "anagine_service_account" {
  description = "Kubernetes service account used by Anagine API pods"
  type        = string
  default     = "anagine"
}

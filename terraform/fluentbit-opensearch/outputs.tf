output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group Fluent Bit writes to"
  value       = aws_cloudwatch_log_group.fluentbit.name
}

output "role_arn" {
  description = "ARN of the Fluent Bit IRSA role. Use this as the eks.amazonaws.com/role-arn annotation value in ardac1prd/fluentbit/values.yaml."
  value       = module.fluentbit_irsa_role.iam_role_arn
}

output "role_name" {
  description = "Name of the Fluent Bit IRSA role"
  value       = module.fluentbit_irsa_role.iam_role_name
}

output "cloudwatch_policy_arn" {
  description = "ARN of the CloudWatch Logs IAM policy"
  value       = aws_iam_policy.fluentbit_cloudwatch.arn
}

output "opensearch_policy_arn" {
  description = "ARN of the OpenSearch write IAM policy"
  value       = aws_iam_policy.fluentbit_opensearch.arn
}

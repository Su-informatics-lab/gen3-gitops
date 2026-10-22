output "bucket_name" {
  description = "Name of the S3 bucket containing generated Anagine reports"
  value       = aws_s3_bucket.reports.id
}

output "role_arn" {
  description = "ARN of the Anagine IRSA role"
  value       = module.anagine_irsa_role.iam_role_arn
}

output "role_name" {
  description = "Name of the Anagine IRSA role"
  value       = module.anagine_irsa_role.iam_role_name
}

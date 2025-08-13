output "admin_vm_instance_id" {
  description = "Instance ID of the admin VM for Session Manager access"
  value       = var.create_ec2 ? module.ec2_instance[0].id : null
}

output "vpc_id" {
  description = "VPC ID for the admin network"
  value       = var.create_vpc ? module.vpc[0].vpc_id : null
}

output "session_manager_command" {
  description = "AWS CLI command to connect to the admin VM via Session Manager"
  value       = var.create_ec2 ? "aws ssm start-session --target ${module.ec2_instance[0].id} --profile ${var.profile}" : null
}

output "admin_vm_private_ip" {
  description = "Private IP address of the admin VM"
  value       = var.create_ec2 ? module.ec2_instance[0].private_ip : null
}
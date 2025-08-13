variable "profile" {
  description = "AWS profile to use"
  type        = string
}

variable "region" {
  description = "AWS Region to use"
  type        = string
  default     = "us-east-1"
}

variable "zone" {
  description = "Availability zone to use"
  type        = string
  default     = "us-east-1d"
}

variable "prefix" {
  description = "Prefix to use for all resources"
  type        = string
}

variable "create_vpc" {
  description = "Create a VPC"
  type        = bool
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (for NAT Gateway)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (for EC2 instances)"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet outbound internet access"
  type        = bool
  default     = false
}

variable "create_ec2" {
  description = "Create an EC2 instance"
  type        = bool
}

variable "ami_filter" {
  description = "Name filter used to find Packer-generated AMI"
  type        = string
}

variable "instance_type" {
  description = "Instance type to use for the EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Key pair to use for the EC2 instance"
  type        = string
}

variable "gen3_profile" {
  description = "Name of profile to create for Gen3 deployment(s)"
  type        = string
}

variable "gen3_tf_user" {
  description = "Name of Terraform user for Gen3 deployment(s)"
  type        = string
}

variable "admin_user" {
  description = "Admin username"
  type        = string
}
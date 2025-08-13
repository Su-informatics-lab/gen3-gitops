# Root Terragrunt configuration
# This file contains the common configuration for all Terragrunt deployments
# Point to the Terraform source code

terraform {
  source = "../../../../terraform/jump"
}

# Configure the remote state backend
remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    bucket  = local.state_bucket_name
    key     = "jump/${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Local values for computed defaults
locals {
  # Auto-generated name
  aws_account       = get_env("AWS_ACCOUNT_ID")
  bucket_hash       = substr(sha256(local.aws_account), 0, 8)
  state_bucket_name = "gen3-terraform-state-${local.bucket_hash}"
}

# Configure the AWS provider
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"  # More flexible constraint
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.2.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
  }
}

provider "aws" {
  profile = var.profile
  region  = var.region
}
EOF
}

# Common inputs that can be overridden by child terragrunt.hcl files
inputs = {
  # AWS Configuration
  profile = "default" # Usually overridden per environment
  region  = "us-east-1"
  zone    = "us-east-1d"

  # VPC Configuration defaults
  create_vpc          = true
  vpc_cidr            = "10.128.0.0/20"
  public_subnet_cidr  = "10.128.1.0/24"
  private_subnet_cidr = "10.128.2.0/24"
  enable_nat_gateway  = true

  # EC2 Configuration defaults
  create_ec2    = true
  instance_type = "t3.medium"
  key_name      = "your-key-name" # Should be overridden per environment
  ami_filter    = "gen3-admin-*"  # Default AMI filter pattern

  # Gen3 Configuration
  gen3_profile = "default"
  gen3_tf_user = "terraform"
  admin_user   = "ubuntu"
}

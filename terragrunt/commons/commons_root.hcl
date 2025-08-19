# Root terragrunt.hcl
# This file defines common configurations that will be inherited by all environments

# Configure Terraform source for all environments
# References the develop branch of the forked gen3-terraform repository
terraform {
  source = "git::https://github.com/alan-walsh/gen3-terraform.git//tf_files/aws/commons?ref=develop"
}

locals {
  # Shared state bucket for all deployments - globally unique based on AWS account or root directory
  root_dir          = get_parent_terragrunt_dir()
  aws_account       = get_env("AWS_ACCOUNT_ID")
  bucket_hash       = substr(sha256(local.aws_account), 0, 8)
  state_bucket_name = "gen3-terraform-state-${local.bucket_hash}"
  # Keep environment-specific users bucket
  region = "us-east-1"
}

# Configure remote state backend
remote_state {
  backend = "s3"

  config = {
    bucket         = local.state_bucket_name
    key            = "commons/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    #use_lockfile = true # Comment out above line and uncomment this if/when Terraform v1.10 or later is in use
  }
}

# Input values that are common across all environments
inputs = {
  # Default values that can be overridden by environment-specific configurations
  aws_region                  = local.region
  ami_account_id              = "099720109477"
  peering_cidr                = "10.128.0.0/20"
  squid_image_search_criteria = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"

  # Default database settings
  deploy_aurora = true
  deploy_rds    = false

  # Default EKS settings
  eks_version                      = "1.31"
  use_asg                          = false
  use_karpenter                    = true
  deploy_karpenter_in_k8s          = true
  karpenter_version                = "v0.32.9"
  eks_public_access                = false
  deploy_argocd                    = false
  deploy_external_secrets_operator = false
  enable_vpc_endpoints             = true
  deploy_cloud_trail               = true

  # Default Gen3 service flags
  deploy_gen3 = false

  # Default WAF rules
  base_rules = [
    {
      managed_rule_group_name = "AWSManagedRulesAmazonIpReputationList"
      priority                = 0
      override_to_count       = ["AWSManagedReconnaissanceList"]
    },
    {
      managed_rule_group_name = "AWSManagedRulesPHPRuleSet"
      priority                = 1
      override_to_count       = ["PHPHighRiskMethodsVariables_HEADER", "PHPHighRiskMethodsVariables_QUERYSTRING", "PHPHighRiskMethodsVariables_BODY"]
    },
    {
      managed_rule_group_name = "AWSManagedRulesWordPressRuleSet"
      priority                = 2
      override_to_count       = ["WordPressExploitableCommands_QUERYSTRING", "WordPressExploitablePaths_URIPATH"]
    },
  ]
  additional_rules = []
}

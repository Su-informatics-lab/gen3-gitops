# Development Environment Terragrunt Configuration
# This file configures the Gen3 platform for the development environment

# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Parse the file path to extract environment and component information
  environment_vars = read_terragrunt_config("env.hcl")
  region_vars      = read_terragrunt_config("region.hcl")

  # Use account-specific users bucket
  aws_account       = get_env("AWS_ACCOUNT_ID")
  bucket_hash       = substr(sha256(local.aws_account), 0, 8)
  users_bucket_name = "gen3-users-${local.bucket_hash}"

  # Extract environment name and project from the folder structure
  environment = local.environment_vars.locals.environment
  project     = local.environment_vars.locals.project
  aws_region  = local.region_vars.locals.aws_region

  # Common tags applied to all resources
  common_tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "terragrunt"
    Owner       = "rds"
  }
}

# Development-specific inputs
inputs = {
  vpc_name   = local.environment
  vpc_cidr_block    = "10.148.0.0/20"
  aws_region = local.aws_region
  hostname   = "new.portal.ardac.org"
  kube_ssh_key = "aw-vscode"
  ami_account_id                 = "amazon"
  squid_image_search_criteria    = "amzn2-ami-hvm-*-x86_64-gp2"
  ha-squid_instance_drive_size   = 30
  ha_squid_single_instance       = true
  deploy_ha_squid                = true
  deploy_sheepdog_db             = false
  deploy_fence_db                = false
  deploy_indexd_db               = false
  network_expansion              = true
  users_policy                   = "dev"
  es_version                     = "7.10"
  #es_linked_role                 = local.es_linked_role
  deploy_aurora                  = true
  deploy_rds                     = false
  use_asg                        = false
  use_karpenter                  = true
  deploy_karpenter_in_k8s        = true
  send_logs_to_csoc              = false
  secrets_manager_enabled        = true
  force_delete_bucket            = true
  enable_vpc_endpoints           = true
  cluster_engine_version         = "13"
}
# Development Environment Terragrunt Configuration
# This file configures the Gen3 platform for the development environment

# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders("commons_root.hcl")
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
  region      = local.region_vars.locals.aws_region

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
  # Environment identification
  vpc_name = local.environment
  hostname = "ipo.sulab.io"

  # Networking
  vpc_cidr_block    = "10.148.0.0/20"
  peering_cidr      = "10.128.0.0/20"
  peering_vpc_id    = "vpc-0f0551c497fbe9b0e"
  vpc_flow_logs     = false
  vpc_flow_traffic  = "ALL"
  network_expansion = false

  # Security & Access
  csoc_account_id   = get_env("CSOC_ACCOUNT_ID", "")
  csoc_managed      = true
  csoc_peering      = false
  fips              = false
  send_logs_to_csoc = false

  # Database sizing for dev (smaller instances)
  fence_db_size        = 10
  sheepdog_db_size     = 10
  indexd_db_size       = 10
  fence_db_instance    = "db.t3.small"
  sheepdog_db_instance = "db.t3.small"
  indexd_db_instance   = "db.t3.small"

  # High availability (disabled for dev)
  fence_ha    = false
  sheepdog_ha = false
  indexd_ha   = false

  # Deployment flags (dev-appropriate)
  deploy_single_proxy = true
  deploy_ha_squid     = true
  deploy_sheepdog_db  = true
  deploy_fence_db     = true
  deploy_indexd_db    = true
  deploy_eks          = true
  deploy_es           = false
  deploy_waf          = false
  deploy_workflow     = false
  deploy_jupyter      = true
  deploy_aurora       = true
  deploy_rds          = false

  # Instance sizing
  instance_type              = "t3.large"
  jupyter_instance_type      = "t3.large"
  workflow_instance_type     = "t3.2xlarge"
  single_squid_instance_type = "t2.micro"
  ha-squid_instance_type     = "t3.medium"
  worker_drive_size          = 30
  jupyter_worker_drive_size  = 30
  workflow_worker_drive_size = 30

  # Elasticsearch configuration
  es_instance_type   = "t3.small.elasticsearch"
  es_instance_count  = 3
  es_version         = "7.10"
  ebs_volume_size_gb = 20
  encryption         = "true"

  # Auto Scaling Groups for dev
  jupyter_asg_desired_capacity  = 0
  jupyter_asg_max_size          = 5
  jupyter_asg_min_size          = 0
  workflow_asg_desired_capacity = 0
  workflow_asg_max_size         = 10
  workflow_asg_min_size         = 0

  # HA Squid settings
  ha-squid_cluster_desired_capasity = 1
  ha-squid_cluster_min_size         = 1
  ha-squid_cluster_max_size         = 2

  # Application configuration
  config_folder = "config"
  portal_app    = "gitops"
  namespace     = "default"

  # Gen3 service configuration
  indexd_prefix = "dg.GAIPO/"

  # Monitoring and alerting
  alarm_threshold = "85"

  # Storage
  fence_max_allocated_storage    = 0
  sheepdog_max_allocated_storage = 0
  indexd_max_allocated_storage   = 0

  # Bootstrap scripts
  bootstrap_script          = "bootstrap-with-security-updates.sh"
  jupyter_bootstrap_script  = "bootstrap-with-security-updates.sh"
  workflow_bootstrap_script = "bootstrap.sh"

  # Kubernetes configuration
  workers_subnet_size = 24
  ec2_keyname         = "aw-vscode"

  # ArgoCD and other tools
  deploy_argocd                     = false
  argocd_version                    = "7.8.2"
  deploy_external_secrets_operator  = false
  external_secrets_operator_version = "0.14.0"
  k8s_bootstrap_resources           = true
  use_karpenter                     = true
  deploy_karpenter_in_k8s           = true

  # User sync configuration
  usersync_schedule = "*/30 * * * *"

  # Database names
  fence_database_name    = "fence"
  sheepdog_database_name = "gdcapi"
  indexd_database_name   = "indexd"

  # Database usernames
  fence_db_username    = "fence_user"
  sheepdog_db_username = "sheepdog"
  indexd_db_username   = "indexd_user"

  # Additional configuration
  dual_proxy              = false
  single_az_for_jupyter   = false
  secrets_manager_enabled = false
  ci_run                  = false

  # Git configuration
  gitops_path = "https://github.com/uc-cdis/cdis-manifest.git"

  # Certificate configuration
  aws_cert_name = get_env("ACM_CERT_ARN")

  # Squid configuration
  #squid-nlb-endpointservice-name = "com.amazonaws.vpce.us-east-1.vpce-svc-0ce2261f708539011"

  # IAM configuration
  iam_role_name      = "csoc_adminvm"
  iam-serviceaccount = true

  # Network policy
  netpolicy_enabled = false

  # Public datasets
  public_datasets = false

  # Tier access
  tier_access_level = "private"
  tier_access_limit = "100"

  # AWS ES Proxy
  aws-es-proxy_enabled = true

  # DBGap integration
  dbgap_enabled    = false
  slack_send_dbgap = false

  # Datadog monitoring
  dd_enabled = false

  # Dictionary URL
  dictionary_url = ""

  # Dispatcher configuration
  dispatcher_job_number = 10

  # Ingress configuration
  ingress_enabled = true

  # RevProxy configuration
  revproxy_arn = ""

  # User sync paths
  users_bucket_name = "${local.users_bucket_name}"
  useryaml_s3_path  = "s3://${local.users_bucket_name}/${local.environment}/user.yaml"
  useryaml_path     = ""
  fence_config_path = ""

  # Upload bucket
  upload_bucket = ""

  # Route table
  route_table_name = "eks_private"

  # Additional CIDR routing - commented out to prevent module errors
  # cidrs_to_route_to_gw = []
  secondary_cidr_block = ""

  # Branch configuration for testing
  branch = "master"

  # Bucket access ARNs - commented out to prevent module errors
  # fence-bot_bucket_access_arns = []

  # Additional deployment flags to prevent module issues
  # These help avoid count-related errors in the Gen3 modules
  deploy_fence_bot = false # Disable fence-bot module if supported

  # Additional squid variables
  ha-squid_bootstrap_script    = "squid_running_on_docker.sh"
  ha-squid_extra_vars          = ["squid_image=master"]
  ha-squid_instance_drive_size = 25

  # Kernel specification
  kernel = "N/A"

  # Activation credentials (should be set via environment variables)
  activation_id = ""
  customer_id   = ""

  # Aurora configuration
  cluster_identifier                = "aurora-cluster"
  cluster_instance_identifier       = "aurora-cluster-instance"
  cluster_instance_class            = "db.serverless"
  cluster_engine                    = "aurora-postgresql"
  cluster_engine_version            = "14"
  master_username                   = "postgres"
  storage_encrypted                 = true
  apply_immediate                   = true
  engine_mode                       = "provisioned"
  serverlessv2_scaling_min_capacity = "0.0"
  serverlessv2_scaling_max_capacity = "10.0"
  skip_final_snapshot               = true
  final_snapshot_identifier         = "aurora-cluster-snapshot-final"
  backup_retention_period           = 7
  preferred_backup_window           = "02:00-03:00"
  password_length                   = 32
  db_kms_key_id                     = ""

  # RDS check lambda
  deploy_rds_check_lambda = false

  # ES linked role
  es_linked_role   = true
  spot_linked_role = false

  # ES role deployment
  deploy_es_role = false

  # ES name
  es_name = ""

  # Sensitive variables - these should be set via environment variables or secret management
  # Using get_env() to pull from environment variables with fallback to empty strings
  db_password_fence             = get_env("DB_PASSWORD_FENCE", "")
  db_password_peregrine         = get_env("DB_PASSWORD_PEREGRINE", "")
  db_password_sheepdog          = get_env("DB_PASSWORD_SHEEPDOG", "")
  db_password_indexd            = get_env("DB_PASSWORD_INDEXD", "")
  hmac_encryption_key           = get_env("HMAC_ENCRYPTION_KEY", "")
  sheepdog_secret_key           = get_env("SHEEPDOG_SECRET_KEY", "")
  sheepdog_indexd_password      = get_env("SHEEPDOG_INDEXD_PASSWORD", "")
  sheepdog_oauth2_client_id     = get_env("SHEEPDOG_OAUTH2_CLIENT_ID", "")
  sheepdog_oauth2_client_secret = get_env("SHEEPDOG_OAUTH2_CLIENT_SECRET", "")
  slack_webhook                 = get_env("SLACK_WEBHOOK", "")
  secondary_slack_webhook       = get_env("SECONDARY_SLACK_WEBHOOK", "")
  mailgun_api_key               = get_env("MAILGUN_API_KEY", "")
  kube_ssh_key                  = get_env("KUBE_SSH_KEY", "")
  kube_additional_keys          = get_env("KUBE_ADDITIONAL_KEYS", "")
  google_client_id              = get_env("GOOGLE_CLIENT_ID", "")
  google_client_secret          = get_env("GOOGLE_CLIENT_SECRET", "")
  fence_access_key              = get_env("FENCE_ACCESS_KEY", "")
  fence_secret_key              = get_env("FENCE_SECRET_KEY", "")

  # Users policy (this needs to be defined based on your requirements)
  users_policy = "${local.environment}"
}
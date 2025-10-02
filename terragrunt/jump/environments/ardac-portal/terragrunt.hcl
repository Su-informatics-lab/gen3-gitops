# Dev environment Terragrunt configuration
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Environment-specific inputs - only override what's different from root defaults
inputs = {
  # Environment-specific overrides
  prefix       = "gen3-admin-ardac-portal"  # Change this to your desired prefix
  profile      = "ardac-portal-tf"         # Change this to your dev AWS profile if different
  key_name     = "aw-vscode"       # Override with your actual dev key pair name
  gen3_tf_user = "gen3-terraform" # Override if using different terraform user for dev
}

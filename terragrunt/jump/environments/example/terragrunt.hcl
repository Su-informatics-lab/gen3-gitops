# Dev environment Terragrunt configuration
include "root" {
  path = find_in_parent_folders("admin_root.hcl")
}

# Environment-specific inputs
inputs = {
  prefix       = "gen3-admin-example"
  profile      = "example-tf"         # Change this to your dev AWS profile if different
  key_name     = "example-keys"       # Override with your actual dev key pair name
  gen3_tf_user = "gen3-terraform" # Override if using different terraform user for dev
}

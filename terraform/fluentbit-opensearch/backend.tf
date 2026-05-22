terraform {
  backend "s3" {
    bucket  = "ardac-portal-terraform-state-705452667"
    region  = "us-east-1"
    encrypt = true
    # key is supplied at init time via -backend-config so the module stays
    # reusable across environments:
    #
    #   terraform init -backend-config="key=ardac1prd/fluentbit-opensearch/terraform.tfstate"
    #
    # For future environments substitute the prefix accordingly, e.g.:
    #   key=ardac1dmo/fluentbit-opensearch/terraform.tfstate
  }
}

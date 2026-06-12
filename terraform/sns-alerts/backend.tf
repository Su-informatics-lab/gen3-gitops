terraform {
  backend "s3" {
    region  = "us-east-1"
    encrypt = true
    # bucket and key are supplied at init time via -backend-config so the
    # module stays reusable across environments:
    #
    #   terraform init \
    #     -backend-config="bucket=ardac-portal-terraform-state-705452667" \
    #     -backend-config="key=ardac1prd/sns-alerts/terraform.tfstate"
    #
    # For future environments substitute bucket and key accordingly.
  }
}

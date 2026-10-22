terraform {
  backend "s3" {
    region  = "us-east-1"
    encrypt = true
    # Supply the bucket and key during initialization so this module remains
    # reusable across environments:
    #
    #   terraform init \
    #     -backend-config="bucket=ardac-portal-terraform-state-705452667" \
    #     -backend-config="key=ardac2prd/anagine/terraform.tfstate"
  }
}

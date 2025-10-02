# Terragrunt Deployment

This directory contains Terragrunt configurations for deploying the Gen3 Admin infrastructure across multiple environments. The deployment creates EC2 instances in private subnets with optional NAT Gateway for outbound internet access, designed for AWS Session Manager connectivity.

## Architecture

- **Private Subnets**: EC2 instances are deployed in private subnets for security
- **NAT Gateway**: Optional feature (enabled by default) that provides outbound internet access for package updates and AWS API calls
- **No SSH Access**: Uses AWS Session Manager for secure shell access
- **Session Manager**: Connect to instances without exposing SSH ports or managing keys

> **💡 Cost Optimization**: NAT Gateway is disabled by default (`enable_nat_gateway = false`) to reduce costs. Enable it only when outbound internet access is required for package installations or external API calls.

## Structure

```
terragrunt/jump/
├── root.hcl                          # Root configuration with common settings
├── .env.example                      # Template for environment variables
├── README.md                         # This file
└── environments/
    ├── example/
    │   ├── env.hcl                   # Environment-specific variables
    │   ├── region.hcl                # Region configuration
    │   └── terragrunt.hcl            # Environment configuration
    └── gaipo/
        ├── env.hcl                   # Environment-specific variables
        ├── region.hcl                # Region configuration
        └── terragrunt.hcl            # Environment configuration
```

## Prerequisites

1. **Install Terragrunt**: Download from [https://terragrunt.gruntwork.io/docs/getting-started/install/](https://terragrunt.gruntwork.io/docs/getting-started/install/)
2. **AWS Credentials**: Configure your AWS credentials and profile
3. **S3 Bucket**: The bucket will be created automatically with a unique name

## S3 State Bucket Configuration

The Terraform state is stored in an S3 bucket. By default, Terragrunt will use an auto-generated bucket name: `gen3-admin-state-<hash>` where the hash is generated from your directory path to ensure uniqueness and consistency.

## Connecting to Instances

### Using AWS Session Manager

Connect to your EC2 instances using AWS Session Manager (no SSH keys required):

```bash
# Get the instance ID from Terragrunt output
cd environments/dev
terragrunt output admin_vm_instance_id

# Connect using Session Manager
aws ssm start-session --target <instance-id> --profile <your-profile>
```

### Prerequisites for Session Manager

1. AWS CLI installed and configured
2. Session Manager plugin: `aws ssm install-plugin`
3. Appropriate IAM permissions for Session Manager

## Usage

### Deploy to Example Environment

```bash
cd environments/example
terragrunt plan
terragrunt apply
```

### Deploy to Gaipo Environment

```bash
cd environments/gaipo
terragrunt plan
terragrunt apply
```

### Destroy Resources

```bash
cd environments/example
terragrunt destroy
```

## Terraform Module Structure

The Terraform module has been consolidated into a clean, modular structure:

```
terraform/
├── main.tf                    # All resources consolidated (VPC, IAM, EC2, S3)
├── variables.tf               # All variable definitions
├── outputs.tf                 # Output definitions
└── templates/
    └── write_files.tpl       # Cloud-init template for EC2 user data
```

## Configuration

### Root Configuration (`root.hcl`)

- Defines the S3 backend configuration
- Generates the provider configuration
- Sets common default values for all environments
- Includes defaults for AWS config, VPC settings, and EC2 configuration

### Environment Configurations

Each environment directory contains:
- `env.hcl`: Environment-specific variables (environment name, project name)
- `region.hcl`: AWS region configuration
- `terragrunt.hcl`: Environment configuration that:
  - Includes the root configuration
  - Points to the Terraform source code
  - Only overrides environment-specific values
  - Can override any other defaults as needed

### NAT Gateway Configuration

The `enable_nat_gateway` variable controls whether a NAT Gateway is deployed:

```hcl
inputs = {
  enable_nat_gateway = true   # Enable for outbound internet access
  # ... other configuration
}
```

**Important considerations:**
- **Cost**: NAT Gateways incur hourly charges (~$45/month) plus data processing fees
- **Default**: Enabled (`true`) to facilitate external connectivity
- **When to enable**: Required for package installations, OS updates, or external API calls from private instances

## Customization

To customize for your environment:

1. **S3 Bucket**: Either set the `TG_BUCKET_NAME` environment variable or let Terragrunt use the auto-generated default name
2. Modify environment-specific variables in each environment's `terragrunt.hcl`
3. Update AWS credentials and profile settings as needed

**Note**: DynamoDB table is no longer required as AWS S3 now supports native state locking.

## Benefits of This Setup

- **DRY (Don't Repeat Yourself)**: Common configuration is defined once
- **Environment Isolation**: Each environment has its own state file
- **Consistent Deployments**: Same Terraform code deployed across environments
- **Easy Management**: Simple commands to deploy/destroy environments

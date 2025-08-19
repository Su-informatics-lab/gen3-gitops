# Gen3 Terragrunt Deployment

This directory contains a Terragrunt-based deployment structure for Gen3 platform infrastructure. Terragrunt is a thin wrapper around Terraform that provides additional functionality for managing infrastructure as code at scale.

## Directory Structure

```
terragrunt/
├── ua-vpit-rt-rds-dev/         # AWS Account folder (account-specific)
│   ├── terragrunt.hcl          # Root configuration for this account
│   ├── region.hcl              # AWS region configuration
│   ├── .env.example            # Template for environment variables
│   └── rds-dev/                # Deployment environment
│       ├── env.hcl             # Environment variables
│       ├── region.hcl          # Environment region settings
│       └── terragrunt.hcl      # Environment configuration
├── another-account/            # Another AWS Account folder
│   ├── terragrunt.hcl          # Root configuration for that account
│   ├── dev/                    # Development deployment
│   ├── staging/                # Staging deployment
│   └── prod/                   # Production deployment
```

**Key Structure Concepts:**
- **Account Folders**: Each top-level folder represents an AWS account (e.g., `ua-vpit-rt-rds-dev`)
- **Account Root**: Contains the root `terragrunt.hcl` with account-wide settings
- **Deployment Folders**: Sub-folders within each account represent individual deployments/environments
- **Environment Isolation**: Each deployment has its own state file within the account's shared S3 bucket

## How It Works

### 1. Account-Level Configuration

Each AWS account folder contains its own root `terragrunt.hcl` file with:
- **Terraform Source**: Points to the gen3-terraform repository on GitHub
- **Remote State Configuration**: Configures S3 backend with account-specific shared bucket
- **Provider Generation**: Automatically generates AWS provider configuration
- **Default Values**: Sets sensible defaults for all deployments in this account
- **State Bucket**: Unique bucket name based on AWS account ID (if available) or directory hash

### 2. Deployment Configuration

Each deployment directory within an account contains:
- `env.hcl`: Deployment-specific variables (environment name, project name)
- `region.hcl`: AWS region configuration for the deployment
- `terragrunt.hcl`: Deployment-specific configuration that inherits from account root

### 3. State Management

- **Account-Level Bucket**: Each AWS account gets its own S3 bucket for state storage
- **Deployment-Level Keys**: Each deployment uses a unique key within the account's bucket
- **Bucket Naming**: `gen3-terraform-state-<account-hash>` where hash is based on AWS_ACCOUNT_ID or directory path
- **State File Paths**: `<deployment-name>/terraform.tfstate` (e.g., `rds-dev/terraform.tfstate`)

## Key Benefits of This Structure

1. **Account Isolation**: Each AWS account has its own configuration and state storage
2. **DRY (Don't Repeat Yourself)**: Common configuration is defined once per account
3. **Deployment Isolation**: Each deployment has its own state file within the account
4. **Flexible Organization**: Support for multiple AWS accounts with multiple deployments each
5. **Consistent Naming**: Resources are named consistently across deployments
6. **Easy Scaling**: New accounts and deployments can be added easily
7. **Override Capability**: Deployment-specific values can override account defaults

## Prerequisites

1. **Terragrunt**: Install Terragrunt (version 0.50.0 or later)
   ```powershell
   # Windows (using Chocolatey)
   choco install terragrunt
   
   # Windows (using Scoop)
   scoop install terragrunt
   ```
   
   ```bash
   # macOS (using Homebrew)
   brew install terragrunt
   
   # Linux (using package manager)
   # Ubuntu/Debian
   sudo apt update
   sudo apt install -y wget unzip
   wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
   sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
   sudo chmod +x /usr/local/bin/terragrunt
   
   # CentOS/RHEL/Fedora
   sudo dnf install -y wget unzip
   wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
   sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
   sudo chmod +x /usr/local/bin/terragrunt
   
   # Or download from: https://github.com/gruntwork-io/terragrunt/releases
   ```

2. **Terraform**: Install Terraform (version 1.0 or later)
   ```powershell
   # Windows (using Chocolatey)
   choco install terraform
   
   # Windows (using Scoop)
   scoop install terraform
   ```
   
   ```bash
   # macOS (using Homebrew)
   brew install terraform
   
   # Linux (using package manager)
   # Ubuntu/Debian
   sudo apt update
   sudo apt install -y gnupg software-properties-common
   wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
   echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   sudo apt update
   sudo apt install terraform
   
   # CentOS/RHEL/Fedora
   sudo dnf install -y dnf-plugins-core
   sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
   sudo dnf install terraform
   ```

3. **AWS CLI**: Install and configure AWS credentials
   ```powershell
   # Windows (using Chocolatey)
   choco install awscli
   
   # Windows (using Scoop)
   scoop install aws
   ```
   
   ```bash
   # macOS (using Homebrew)
   brew install awscli
   
   # Linux (using package manager)
   # Ubuntu/Debian
   sudo apt update
   sudo apt install -y awscli
   
   # CentOS/RHEL/Fedora
   sudo dnf install -y awscli
   
   # Or using pip (all platforms)
   pip install awscli
   ```
   
   Configure AWS credentials:
   ```bash
   aws configure
   ```

## Usage

### Initial Setup

1. **Create DynamoDB Table for State Locking** (one-time setup):
   ```powershell
   # PowerShell
   aws dynamodb create-table `
     --table-name terraform-state-lock `
     --attribute-definitions AttributeName=LockID,AttributeType=S `
     --key-schema AttributeName=LockID,KeyType=HASH `
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 `
     --region us-east-1
   ```

   ```bash
   # Linux/Mac
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
     --region us-east-1
   ```

2. **Set Required Environment Variables**:
   
   **Option 1: Using .env file (Recommended)**
   ```bash
   # Copy the example environment file
   cp .env.example .env
   
   # Edit the .env file with your actual values
   # Replace all REPLACE_WITH_* values with real secrets
   
   # Source the environment variables (Linux/Mac)
   source .env
   ```
   
   **Option 2: Set variables directly**
   ```powershell
   # PowerShell (Windows)
   $env:DB_PASSWORD_FENCE="your-fence-password"
   $env:DB_PASSWORD_SHEEPDOG="your-sheepdog-password"
   $env:DB_PASSWORD_INDEXD="your-indexd-password"
   $env:HMAC_ENCRYPTION_KEY="your-32-char-key"
   $env:SHEEPDOG_SECRET_KEY="your-sheepdog-key"
   # ... add other sensitive variables as needed
   ```

   ```bash
   # Bash (Linux/Mac)
   export DB_PASSWORD_FENCE="your-fence-password"
   export DB_PASSWORD_SHEEPDOG="your-sheepdog-password"
   export DB_PASSWORD_INDEXD="your-indexd-password"
   export HMAC_ENCRYPTION_KEY="your-32-char-key"
   export SHEEPDOG_SECRET_KEY="your-sheepdog-key"
   # ... add other sensitive variables as needed
   ```

### Deploying to an AWS Account

1. **Navigate to the account directory**:
   ```bash
   cd ua-vpit-rt-rds-dev/
   ```

2. **Set up environment variables** (copy and edit .env.example):
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   source .env  # Linux/Mac
   ```

3. **Navigate to the deployment directory**:
   ```bash
   cd rds-dev/
   ```

4. **Initialize Terragrunt**:
   ```bash
   terragrunt init
   ```

5. **Plan the deployment**:
   ```bash
   terragrunt plan
   ```

6. **Apply the changes**:
   ```bash
   terragrunt apply
   ```

7. **Destroy the infrastructure** (when needed):
   ```bash
   terragrunt destroy
   ```

### Working with Multiple Accounts and Deployments

You can manage multiple AWS accounts and deployments:

```bash
# Deploy to account ua-vpit-rt-rds-dev, deployment rds-dev
cd ua-vpit-rt-rds-dev/rds-dev/
terragrunt apply

# Deploy to another account, development deployment
cd ../another-account/dev/
terragrunt apply

# Deploy to the same account, staging deployment
cd ../staging/
terragrunt apply
```

## Configuration Files Explained

### `terragrunt.hcl` (Root)

- **Remote State**: Configures S3 backend with environment-specific keys
- **Provider Generation**: Creates AWS provider with default tags
- **Common Inputs**: Default values shared across all environments
- **DRY Configuration**: Reduces duplication across environments

### `env.hcl`

Contains environment-specific variables:
```hcl
locals {
  environment = "dev"
  project     = "gen3-iac"
}
```

These values are used for:
- Resource tagging (Environment and Project tags)
- State file organization
- Resource naming conventions

### Environment `terragrunt.hcl`

- **Include Root**: Inherits from root configuration using `include "root"`
- **Local Variables**: Reads environment and project from `env.hcl`
- **Environment Inputs**: Environment-specific variable values
- **Override Logic**: Can override any default values from root configuration

## Customizing for Your Environment

### Adding a New AWS Account

1. Create a new account directory (e.g., `my-aws-account/`)
2. Copy the `terragrunt.hcl` from an existing account folder
3. Copy the `region.hcl` and `.env.example` files
4. Create deployment subdirectories as needed

### Adding a New Deployment to an Existing Account

1. Create a new deployment directory (e.g., `my-aws-account/prod/`)
2. Copy `env.hcl` from an existing deployment and update:
   ```hcl
   locals {
     environment = "prod"
     project     = "gen3-iac"
   }
   ```
3. Copy `region.hcl` and `terragrunt.hcl` from an existing deployment
4. Modify deployment-specific values in `terragrunt.hcl`

### Modifying Variables

1. **Account-wide Changes**: Edit the account's root `terragrunt.hcl`
2. **Deployment-Specific**: Edit the deployment's `terragrunt.hcl`
3. **Sensitive Values**: Use environment variables without prefix or `.env` file

### Configuring Environment and Project Tags

Each deployment can specify its own environment name and project name through the `env.hcl` file:

```hcl
# ua-vpit-rt-rds-dev/rds-dev/env.hcl
locals {
  environment = "rds-dev"
  project     = "gen3-iac"
}
```

These values are used for:
- **Resource Tagging**: All AWS resources get tagged with Environment and Project
- **State File Naming**: Terraform state files are organized by deployment
- **Resource Naming**: Many resources include the deployment name in their names

Example for a custom deployment:
```hcl
# my-account/production/env.hcl
locals {
  environment = "production"
  project     = "clinical-data-platform"
}
```

This will result in resources being tagged with:
- `Environment = "production"`
- `Project = "clinical-data-platform"`
- `ManagedBy = "terragrunt"`
- `Owner = "gen3-team"`

### Using Different Terraform Versions

You can specify Terraform version constraints in the root `terragrunt.hcl`:

```hcl
terraform_version_constraint = ">= 1.0"
terragrunt_version_constraint = ">= 0.50.0"
```

## Best Practices

1. **Sensitive Data**: Never commit sensitive values to Git. Use environment variables or AWS Secrets Manager
2. **State Management**: Always use remote state with locking
3. **Consistent Naming**: Follow the established naming conventions
4. **Gradual Rollout**: Test changes in dev before applying to production
5. **Version Control**: Tag releases and use consistent versioning
6. **Documentation**: Keep this README updated as the infrastructure evolves

## Troubleshooting

### Common Issues

1. **State Lock Conflicts**:
   ```bash
   terragrunt force-unlock <lock-id>
   ```

2. **Variable Errors**:
   - Check that all required variables are set
   - Verify environment variable names are uppercase without prefix

3. **AWS Permissions**:
   - Ensure AWS credentials have sufficient permissions
   - Check IAM policies for Terraform operations

### Debug Mode

Enable debug logging:
```bash
export TERRAGRUNT_LOG_LEVEL=debug
terragrunt apply
```

### State File Organization

The current configuration creates an S3 bucket per AWS account with unique names:

#### Bucket Naming Strategy
- **With AWS_ACCOUNT_ID**: `gen3-terraform-state-<8-char-hash-of-account-id>`
- **Without AWS_ACCOUNT_ID**: `gen3-terraform-state-<8-char-hash-of-directory-path>`

#### State File Structure
```
Account: ua-vpit-rt-rds-dev
├── S3 Bucket: gen3-terraform-state-a1b2c3d4
│   ├── rds-dev/terraform.tfstate
│   └── staging/terraform.tfstate

Account: another-account
├── S3 Bucket: gen3-terraform-state-e5f6g7h8
│   ├── dev/terraform.tfstate
│   ├── staging/terraform.tfstate
│   └── prod/terraform.tfstate
```

#### Benefits of This Approach
- **Account Isolation**: Each AWS account has its own state bucket
- **Deployment Isolation**: Each deployment has its own state file
- **Consistent Naming**: Predictable bucket names based on account or directory
- **Global Uniqueness**: Hash ensures no conflicts across different setups
- **Cost Efficiency**: One bucket per account instead of per deployment

## Migration from Terraform

If you're migrating from the existing Terraform setup:

1. **Import Existing State** (if needed):
   ```bash
   terragrunt import <resource_type>.<resource_name> <resource_id>
   ```

2. **State Migration**:
   - The state file location will change from the old S3 key to the new environment-specific key
   - You may need to manually migrate state or recreate resources

3. **Variable Validation**:
   - Compare the variables in the old and new configurations
   - Ensure all customizations are preserved

## Security Considerations

1. **State File Security**: The S3 bucket containing state files should have appropriate access controls
2. **Sensitive Variables**: Use AWS Secrets Manager or environment variables for sensitive data
3. **IAM Permissions**: Follow the principle of least privilege for Terraform execution roles
4. **Encryption**: Ensure state files are encrypted at rest (configured in the root terragrunt.hcl)

## Support and Maintenance

- **Terragrunt Documentation**: https://terragrunt.gruntwork.io/
- **Terraform Documentation**: https://www.terraform.io/docs/
- **Gen3 Documentation**: https://gen3.org/

For issues specific to this deployment, refer to the project's issue tracker or contact the Gen3 platform team.

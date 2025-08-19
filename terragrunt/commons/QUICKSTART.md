# Gen3 Terragrunt Quick Start Guide

This guide will help you get started with deploying Gen3 using Terragrunt in just a few steps.

## Understanding the Structure

- **Account Folders**: Each top-level folder represents an AWS account (e.g., `ua-vpit-rt-rds-dev`)
- **Deployment Folders**: Sub-folders within each account represent individual deployments (e.g., `rds-dev`, `staging`, `prod`)
- **Shared State**: All deployments within an account share the same S3 bucket for state storage
- **Account Isolation**: Each AWS account gets its own uniquely named state bucket

## Prerequisites Check

Before starting, ensure you have:

- [ ] Terragrunt installed (v0.50.0+)
- [ ] Terraform installed (v1.0+)
- [ ] AWS CLI configured with appropriate credentials
- [ ] Gen3 Terraform repository cloned to your home directory
- [ ] Access to create S3 buckets for state storage (one per AWS account)
- [ ] AWS_ACCOUNT_ID environment variable set (optional, but recommended)
- [ ] All required sensitive variables ready (see .env.example)

## Installing Prerequisites

### Step 1: Install Terragrunt

```powershell
# Windows (using Chocolatey)
choco install terragrunt

# Windows (using Scoop)
scoop install terragrunt
```

```bash
# macOS (using Homebrew)
brew install terragrunt

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install -y wget unzip
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
sudo chmod +x /usr/local/bin/terragrunt

# Linux (CentOS/RHEL/Fedora)
sudo dnf install -y wget unzip
wget https://github.com/gruntwork-io/terragrunt/releases/download/v0.50.0/terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
sudo chmod +x /usr/local/bin/terragrunt
```

### Step 2: Install Terraform

```powershell
# Windows (using Chocolatey)
choco install terraform

# Windows (using Scoop)
scoop install terraform
```

```bash
# macOS (using Homebrew)
brew install terraform

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt install terraform

# Linux (CentOS/RHEL/Fedora)
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install terraform
```

### Step 3: Install AWS CLI

```powershell
# Windows (using Chocolatey)
choco install awscli

# Windows (using Scoop)
scoop install aws
```

```bash
# macOS (using Homebrew)
brew install awscli

# Linux (Ubuntu/Debian)
sudo apt update
sudo apt install -y awscli

# Linux (CentOS/RHEL/Fedora)
sudo dnf install -y awscli

# Or using pip (all platforms)
pip install awscli
```

Configure AWS credentials:
```bash
aws configure
```

### Step 4: Clone Gen3 Terraform Repository

```bash
# Clone to your home directory (alongside this repository)
cd $HOME  # or cd ~ on Unix systems
git clone https://github.com/uc-cdis/gen3-terraform.git
```

## Quick Start Steps

### 5. Set Up Environment Variables

First, set your AWS account ID (recommended for consistent state bucket naming):

```powershell
# Windows PowerShell
$env:AWS_ACCOUNT_ID="123456789012"  # Replace with your actual AWS account ID
```

```bash
# Linux/Mac
export AWS_ACCOUNT_ID="123456789012"  # Replace with your actual AWS account ID
```

Then set up your deployment variables:

```powershell
# Windows PowerShell - Navigate to your account folder
cd ua-vpit-rt-rds-dev

# Copy the example environment file
copy .env.example .env

# Edit the .env file with your actual values
# Replace all REPLACE_WITH_* values with real secrets
notepad .env

# Set environment variables in PowerShell (example):
$env:DB_PASSWORD_FENCE="your-password"
$env:DB_PASSWORD_SHEEPDOG="your-password"
$env:HMAC_ENCRYPTION_KEY="your-32-char-key"
# ... set other variables as needed
```

```bash
# Linux/Mac - Navigate to your account folder
cd ua-vpit-rt-rds-dev

# Copy the example environment file
cp .env.example .env

# Edit the .env file with your actual values
# Replace all REPLACE_WITH_* values with real secrets
vim .env      # or nano .env

# Source the environment variables
source .env
```

### 6. Create State Lock Table (One-time setup)

```powershell
# PowerShell (Windows)
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

### 7. Deploy Your First Deployment

```bash
# Navigate to your account and deployment
cd ua-vpit-rt-rds-dev/rds-dev/

# Initialize Terragrunt
terragrunt init

# Review the plan
terragrunt plan

# Apply the changes (this will take 15-30 minutes)
terragrunt apply
```

## Customization

### Account-Specific Changes

Edit the account-level `terragrunt.hcl` to set account-wide defaults:

```hcl
# ua-vpit-rt-rds-dev/terragrunt.hcl
inputs = {
  # Account-wide defaults
  aws_region = "us-east-1"
  deploy_aurora = true
  # ... other account-wide settings
}
```

### Deployment-Specific Changes

Edit `<deployment>/env.hcl` to set the deployment name and project:

```hcl
# ua-vpit-rt-rds-dev/rds-dev/env.hcl
locals {
  environment = "rds-dev"
  project     = "my-gen3-project"
}
```

Edit `<deployment>/terragrunt.hcl` to customize deployment settings:

```hcl
# ua-vpit-rt-rds-dev/rds-dev/terragrunt.hcl
inputs = {
  # Change VPC name
  vpc_name = "MyGen3-rds-dev"
  
  # Change hostname
  hostname = "my-gen3-rds-dev.example.com"
  
  # Adjust instance sizes
  instance_type = "t3.medium"  # Smaller for cost savings
  
  # Enable/disable features
  deploy_jupyter = false  # Disable Jupyter for this deployment
  deploy_waf     = true   # Enable WAF for testing
}
```

### Adding New Deployments

1. Create a new deployment directory (e.g., `ua-vpit-rt-rds-dev/staging/`)
2. Copy `rds-dev/env.hcl` to `staging/env.hcl` and update:
   ```hcl
   locals {
     environment = "staging"
     project     = "gen3-iac"
   }
   ```
3. Copy `rds-dev/terragrunt.hcl` to `staging/terragrunt.hcl` and customize values
4. Copy `rds-dev/region.hcl` to `staging/region.hcl`

### Adding New AWS Accounts

1. Create a new account directory (e.g., `my-aws-account/`)
2. Copy the account-level files from an existing account:
   - `terragrunt.hcl` (root configuration)
   - `region.hcl` (region settings)
   - `.env.example` (environment template)
3. Create deployment subdirectories as needed

## Monitoring Your Deployment

### Check Status

```bash
# View current state
terragrunt show

# View outputs
terragrunt output

# Check resource health in AWS Console
```

### Common Commands

```bash
# Update existing infrastructure
terragrunt plan && terragrunt apply

# Import existing resources (if needed)
terragrunt import aws_instance.example i-1234567890abcdef0

# Refresh state
terragrunt refresh

# Force unlock (if locked)
terragrunt force-unlock <lock-id>
```

## Troubleshooting

### Common Issues

1. **State Lock Error**
   ```bash
   # Find and force unlock
   terragrunt force-unlock <lock-id>
   ```

2. **Permission Errors**
   - Check AWS credentials: `aws sts get-caller-identity`
   - Verify IAM permissions for required services

3. **Module Source Issues**
   - Ensure gen3-terraform repository is cloned in your home directory
   - The path should be `$HOME/gen3-terraform/tf_files/aws/commons`
   - Check that the `get_env("HOME")` function can resolve your home directory

4. **Variable Errors**
   - Verify all required environment variables are set
   - Check for typos in variable names (use capitalized names without prefixes)

### Debug Mode

```bash
# Enable debug logging
export TERRAGRUNT_LOG_LEVEL=debug
terragrunt apply
```

### Getting Help

```bash
# Terragrunt help
terragrunt --help

# Terraform help
terraform --help
```

## Security Reminders

- Never commit `.env` file to version control
- Use strong, unique passwords for all database credentials
- Rotate secrets regularly
- Review IAM policies for least privilege access
- Enable AWS CloudTrail for audit logging

## Next Steps

1. **Additional Deployments**: Copy the rds-dev setup to create staging and prod deployments
2. **Additional AWS Accounts**: Create new account folders for different AWS accounts
3. **CI/CD Integration**: Set up automated deployments
4. **Monitoring**: Configure CloudWatch dashboards and alerts
5. **Backup Strategy**: Implement database backup procedures

## Getting Support

- Check the main [README.md](README.md) for detailed documentation
- Review Terragrunt documentation: https://terragrunt.gruntwork.io/
- Gen3 documentation: https://gen3.org/
- AWS documentation for specific services

Happy deploying! 🚀

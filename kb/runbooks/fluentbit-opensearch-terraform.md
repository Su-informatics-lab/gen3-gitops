---
type: Runbook
title: Operate the Fluent Bit OpenSearch Terraform module
description: Procedure for deploying and validating the standalone Terraform module that gives Fluent Bit CloudWatch and OpenSearch access.
tags: [terraform, fluentbit, opensearch, cloudwatch, irsa]
timestamp: 2026-07-09T00:00:00Z
---

# Operate the Fluent Bit OpenSearch Terraform Module

Last reviewed: 2026-07-09

## When To Use

Use this when deploying or changing the standalone Terraform module in `terraform/fluentbit-opensearch`.

The module gives Fluent Bit access to:

- a CloudWatch log group
- an OpenSearch domain
- an IRSA role for the `fluent-bit` Kubernetes service account

## Source Of Truth

- `terraform/fluentbit-opensearch/backend.tf`
- `terraform/fluentbit-opensearch/provider.tf`
- `terraform/fluentbit-opensearch/main.tf`
- `terraform/fluentbit-opensearch/variables.tf`
- `terraform/fluentbit-opensearch/fluentbit-opensearch.auto.tfvars.template`

## Important Ownership Warning

This module manages the full OpenSearch domain access policy through `aws_elasticsearch_domain_policy`.

Before applying, list every existing principal that must keep access in `opensearch_existing_principals`. Omitting a principal can revoke access.

## Procedure

1. Work from the module directory.

   ```bash
   cd terraform\fluentbit-opensearch
   ```

2. Create local tfvars from the template.

   ```bash
   cp fluentbit-opensearch.auto.tfvars.template fluentbit-opensearch.auto.tfvars
   ```

   Do not commit the local `.auto.tfvars` file.

3. Fill in environment values.

   Required values include:

   - `prefix`
   - `cluster_name`
   - `opensearch_domain_name`
   - `log_group_name`
   - `opensearch_existing_principals`

4. Confirm prerequisites.

   - The EKS cluster has an IAM OIDC provider.
   - AWS credentials can read the EKS cluster and OpenSearch domain.
   - Existing OpenSearch access principals are known.
   - The CloudWatch log group ownership is understood.

5. Initialize the backend with environment-specific state.

   Production example from the template:

   ```bash
   terraform init -backend-config="bucket=ardac-portal-terraform-state-705452667" -backend-config="key=ardac1prd/fluentbit-opensearch/terraform.tfstate"
   ```

6. Import an existing CloudWatch log group if needed.

   ```bash
   terraform import aws_cloudwatch_log_group.fluentbit <log_group_name>
   ```

7. Validate and plan.

   ```bash
   terraform fmt -check
   terraform validate
   terraform plan
   ```

8. Apply after reviewing the OpenSearch access policy diff carefully.

   ```bash
   terraform apply
   ```

9. Capture outputs.

   ```bash
   terraform output role_arn
   terraform output cloudwatch_log_group_name
   terraform output opensearch_policy_arn
   ```

   Use `role_arn` as the `eks.amazonaws.com/role-arn` annotation value for the Fluent Bit service account if the Helm values need to be updated.

## Validation After Apply

Check AWS resources:

```bash
aws logs describe-log-groups --profile <profile> --log-group-name-prefix <log-group-name>
aws iam get-role --profile <profile> --role-name <role-name>
aws es describe-elasticsearch-domain-config --profile <profile> --domain-name <domain-name>
```

Check Kubernetes:

```bash
kubectl -n kube-system get serviceaccount fluent-bit -o yaml
kubectl -n kube-system get pods -l app.kubernetes.io/name=fluent-bit
kubectl -n kube-system logs -l app.kubernetes.io/name=fluent-bit --tail=200
```

Check OpenSearch ingestion:

```bash
curl -s "http://localhost:9200/anagine-logs/_count"
```

## Rollback

Rollback depends on what changed:

- For a bad IAM policy attachment, revert the Terraform change and re-apply.
- For a bad OpenSearch domain access policy, restore the missing principals in `opensearch_existing_principals` and re-apply.
- For a bad service account annotation, revert the Helm values change and let Argo CD sync.

Do not destroy the module unless the user explicitly wants to remove Fluent Bit access and understands the impact on logs and OpenSearch ingestion.

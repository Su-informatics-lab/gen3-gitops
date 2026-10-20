# Runbook

* [Make a GitOps change](gitops-change.md) - Branch, worktree, validation, and PR hygiene for repository updates.
* [Investigate and reduce Karpenter disruption](karpenter-disruption.md) - Incident investigation and mitigation for Karpenter-managed Gen3 EKS clusters.
* [Plan and run a Gen3 EKS Kubernetes upgrade](eks-kubernetes-upgrade.md) - Live EKS upgrade procedure for Gen3 deployments with Karpenter, self-managed add-ons, ALB health checks, and stateful workload gates.
* [Update Anagine usage-log routing in Fluent Bit](fluentbit-usage-logs.md) - Procedure for routing structured Anagine `USAGE_LOG` records through Fluent Bit into OpenSearch.
* [Manage ALB listener rules through GitOps](alb-rules.md) - GitOps procedure for ALB redirects, fixed responses, and listener-rule validation.
* [Operate the Fluent Bit OpenSearch Terraform module](fluentbit-opensearch-terraform.md) - Procedure for deploying and validating the standalone Terraform module that gives Fluent Bit CloudWatch and OpenSearch access.

# Documents

* [Runbooks README](README.md) - Human-oriented index of task-oriented procedures for repeated Gen3 GitOps work.

# Parent

* [gen3-gitops OKF](../index.md) - Root OKF directory index.

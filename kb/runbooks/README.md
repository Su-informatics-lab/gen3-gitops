---
type: Index
title: Runbooks
description: Index of task-oriented procedures for repeated Gen3 GitOps work.
tags: [okf, runbooks, gen3-gitops]
timestamp: 2026-07-09T00:00:00Z
---

# Runbooks

Last reviewed: 2026-07-09

These runbooks are for repeated tasks in this repository and closely related Gen3 operations.

Use the runbook that matches the task:

- [Make a GitOps change](gitops-change.md): branch/worktree workflow, validation, PR hygiene.
- [Investigate and reduce Karpenter disruption](karpenter-disruption.md): incident analysis and availability tuning for Karpenter-managed Gen3 clusters.
- [Plan and run a Gen3 EKS Kubernetes upgrade](eks-kubernetes-upgrade.md): live EKS upgrades with Karpenter, self-managed add-ons, ALB checks, and stateful workload gates.
- [Update Anagine usage-log routing in Fluent Bit](fluentbit-usage-logs.md): `USAGE_LOG:` parsing, OpenSearch mapping checks, and Helm validation.
- [Manage ALB listener rules through GitOps](alb-rules.md): host redirects and fixed responses through AWS Load Balancer Controller ingress rules.
- [Operate the Fluent Bit OpenSearch Terraform module](fluentbit-opensearch-terraform.md): S3 backend init, imports, OpenSearch policy preservation, and apply checks.

Before creating a new runbook, search this directory first. Update the closest existing runbook unless the task has a distinct operator goal.

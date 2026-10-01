---
type: Index
title: Knowledge Base README
description: Agent-oriented table of contents and maintenance rules for the gen3-gitops OKF bundle.
tags: [okf, gen3-gitops, agents]
timestamp: 2026-07-09T00:00:00Z
---

# Knowledge Base

Last reviewed: 2026-07-09

This directory is the repository's OKF 0.1 knowledge base. It is intended to help users and agents understand the system, make safe GitOps changes, and repeat operational procedures that have already come up in real work.

## OKF 0.1 Convention

For this repository, OKF 0.1 means:

- each OKF directory has an `index.md` file for progressive disclosure
- `index.md` files are reserved directory listings and do not need frontmatter
- concept documents and runbooks have YAML frontmatter with at least `type`
- `kb/README.md` is the agent-oriented table of contents.
- `kb/concepts/` contains durable system explanations.
- `kb/runbooks/` contains task-oriented procedures.
- Every page should be grounded in repository files, live operational findings, or recent session history.
- Do not add example-only pages, empty folders, or speculative concept files.
- Prefer updating an existing page over creating a near-duplicate page.

Runbooks should generally include:

- when to use the runbook
- source-of-truth files
- prerequisites
- steps
- validation
- rollback or pause points when relevant

## System Docs

- [Gen3 GitOps system map](concepts/gen3-gitops-system.md)

## Runbooks

- [Make a GitOps change](runbooks/gitops-change.md)
- [Investigate and reduce Karpenter disruption](runbooks/karpenter-disruption.md)
- [Plan and run a Gen3 EKS Kubernetes upgrade](runbooks/eks-kubernetes-upgrade.md)
- [Update Anagine usage-log routing in Fluent Bit](runbooks/fluentbit-usage-logs.md)
- [Manage ALB listener rules through GitOps](runbooks/alb-rules.md)
- [Operate the Fluent Bit OpenSearch Terraform module](runbooks/fluentbit-opensearch-terraform.md)

## Maintenance Rules

- Keep links pointed at the current source-of-truth files.
- Record environment-specific values only when they are already committed in this repo or are non-sensitive operational facts.
- Do not commit secrets, decoded credentials, kubeconfigs, Terraform state, generated archives, or local `.auto.tfvars` files.
- When a session produces a reusable procedure, add or update a runbook before the details vanish from working memory.

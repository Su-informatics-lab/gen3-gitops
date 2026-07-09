# Agent Guide

This repository has an OKF 0.1 knowledge base in `kb/`. Use it as the first stop for system context and operational runbooks.

## Session Startup

At the start of a new agent session:

1. Read `kb/index.md` for the OKF-native directory index, then read `kb/README.md` for the agent-oriented table of contents.
2. Use `kb/concepts/index.md` and `kb/runbooks/index.md` to scan available system docs and runbooks.
3. Read `kb/concepts/gen3-gitops-system.md` when the task touches repo structure, Argo CD, Helm values, Terraform, Terragrunt, Karpenter, Fluent Bit, or ALB behavior.
4. Pick the closest runbook from `kb/runbooks/` before proposing or making changes.
5. If no runbook fits, proceed carefully and add or update a runbook when the work produces a reusable procedure.

## Runbook Selection

- Git workflow, validation, PR hygiene: `kb/runbooks/gitops-change.md`
- Karpenter node churn, disruption, Spot interruptions, pod placement: `kb/runbooks/karpenter-disruption.md`
- EKS Kubernetes upgrades for Gen3 deployments: `kb/runbooks/eks-kubernetes-upgrade.md`
- Anagine usage logs, Fluent Bit parsing, OpenSearch fields: `kb/runbooks/fluentbit-usage-logs.md`
- ALB redirects, fixed responses, listener-rule behavior: `kb/runbooks/alb-rules.md`
- Fluent Bit CloudWatch/OpenSearch IAM Terraform: `kb/runbooks/fluentbit-opensearch-terraform.md`

## Working Rules

- Use a branch and worktree for repo updates. Create worktrees under `$CODEX_HOME/worktrees`.
- Keep changes surgical and grounded in the repo, live operational findings, or recent session history.
- Do not create placeholder OKF pages, example-only files, or speculative concept docs.
- Prefer updating an existing OKF page over creating a near-duplicate page.
- Do not commit secrets, decoded credentials, kubeconfigs, Terraform state, generated archives, or local `.auto.tfvars` files. If necessary, add them to `.gitignore` and document the local file usage in a runbook.

## Validation Expectations

Use the narrowest validation that proves the change:

- Markdown/docs: check links, trailing whitespace, and repo status.
- YAML: `yamllint <file>`.
- Kubernetes manifests: `kubectl apply --dry-run=client --validate=false -f <file>`.
- Helm values: render the chart source, including values referenced by the Argo CD `Application`.
- Terraform: `terraform fmt -check`, `terraform init -backend=false` when possible, and `terraform validate`.
- Git diffs: `git diff --check`.

When a task affects production behavior, identify the post-merge or post-sync checks before finishing.

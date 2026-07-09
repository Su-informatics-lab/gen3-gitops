---
type: Runbook
title: Make a GitOps change
description: Branch, worktree, validation, and PR hygiene for repository updates.
tags: [gitops, git, worktree, validation, pull-request]
timestamp: 2026-07-09T00:00:00Z
---

# Make a GitOps Change

Last reviewed: 2026-07-09

## When To Use

Use this for repo changes that alter Argo CD applications, Helm values, raw Kubernetes manifests, Terraform modules, or Terragrunt configuration.

## Assumptions

- Work on a branch and worktree, not directly in the main checkout.
- The preferred branch prefix is `codex/`.
- The worktree belongs under `$CODEX_HOME/worktrees`. If `$CODEX_HOME` is unset, use `$env:USERPROFILE\.codex` (PowerShell).
- This repo targets Windows 11 and PowerShell.

## Procedure

1. Check the current state.

   ```bash
   git status --short --branch
   git worktree list
   git branch --show-current
   ```

2. Create a dedicated worktree and branch.

   ```bash
   git worktree add C:\Users\alwalsh\.codex\worktrees\<worktree-name> -b codex/<branch-name>
   ```

3. Identify the source of truth before editing.

   - Gen3 Helm values: environment `values.yaml` under `ardac1prd/` or `ardac1dmo/`.
   - Cluster-level resources: environment `cluster-values.yaml`.
   - Raw ALB or Kubernetes manifests: `manifests/` directory synced by an Argo CD app.
   - Standalone Terraform: module directory under `terraform/`.
   - Terragrunt commons: `terragrunt/commons`, with remote source configured in `root.hcl`.
   - Jump hosts: `terragrunt/jump`, with local source `terraform/jump`.

4. Make the smallest change that satisfies the task.

   Keep unrelated formatting, comments, line endings, and adjacent configuration unchanged unless they block validation.

5. Validate with the narrowest useful checks.

   ```bash
   git diff --check
   ```

   For YAML:

   ```bash
   yamllint <changed-file.yaml>
   ```

   For raw Kubernetes manifests:

   ```bash
   kubectl apply --dry-run=client --validate=false -f <changed-file.yaml>
   ```

   For Terraform modules:

   ```bash
   terraform fmt -check -recursive .
   terraform init -backend=false
   terraform validate
   ```

   For Helm values, render the chart source named by the relevant Argo CD `Application`. If the app points at `uc-cdis/gen3-helm`, inspect or clone that chart source and render the exact path used by `app.yaml`.

6. Review the diff before staging.

   ```bash
   git diff --stat
   git diff
   ```

7. Commit and push only when requested or when the task includes PR creation.

   ```bash
   git add <files>
   git diff --cached --check
   git commit -m "<message>"
   git push -u origin <branch>
   ```

8. For GitHub PRs, never pass Markdown inline with `--body`.

   Write the PR body to a temp file and use `--body-file`. PowerShell uses the backtick as an escape character, so inline Markdown can be corrupted.

## Post-Merge Checks

After a GitOps change merges and Argo CD syncs:

- Confirm the target Argo CD app is synced and healthy.
- Confirm rendered Kubernetes resources match the intended change.
- For ALB changes, inspect listener rules and test HTTP behavior.
- For workload changes, check deployment readiness, pod placement, PDBs, and ALB target health when relevant.

## Pause Points

Pause and ask before:

- live AWS mutations not represented in Git
- scaling or deleting stateful workloads
- forcing Kubernetes drains past PDBs
- changing Karpenter NodePool policy in a live cluster
- replacing Terraform state or importing resources with uncertain ownership

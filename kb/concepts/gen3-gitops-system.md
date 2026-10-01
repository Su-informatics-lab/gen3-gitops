---
type: Concept
title: Gen3 GitOps system map
description: Durable map of the repository's Argo CD, Helm, Terraform, Terragrunt, Karpenter, Fluent Bit, and ALB surfaces.
tags: [gen3-gitops, argocd, helm, terraform, terragrunt, karpenter, fluentbit, alb]
timestamp: 2026-07-09T00:00:00Z
---

# Gen3 GitOps System Map

Last reviewed: 2026-07-09

## Purpose

This repo stores GitOps configuration for Gen3 deployments. The main operational surfaces are:

- Argo CD `Application` manifests for Gen3, cluster-level resources, Fluent Bit, and raw ALB ingress rules.
- Helm values for ARDAC demo and production Gen3 environments.
- Standalone Terraform modules for supporting infrastructure such as Fluent Bit access to CloudWatch and OpenSearch.

## Environment Layout

Production ARDAC files live under `ardac1prd/`.

- `ardac1prd/portal.ardac.org/app.yaml` renders `uc-cdis/gen3-helm` path `helm/gen3` from `master`, using values from `ardac1prd/portal.ardac.org/values.yaml`.
- `ardac1prd/cluster-level-resources/app.yaml` renders `uc-cdis/gen3-helm` path `helm/cluster-level-resources`, using `ardac1prd/cluster-level-resources/cluster-values.yaml`.
- `ardac1prd/fluentbit/app.yaml` renders chart `fluent/fluent-bit` version `0.57.5`, using `ardac1prd/fluentbit/values.yaml`.
- `ardac1prd/new.portal.ardac.org/app.yaml` syncs raw manifests from `ardac1prd/new.portal.ardac.org/manifests`.

Demo ARDAC files live under `ardac1dmo/` and follow the same broad pattern for Gen3, cluster-level resources, and Fluent Bit.

## Production Gen3 Values

The production Gen3 values file is `ardac1prd/portal.ardac.org/values.yaml`.

Important current settings:

- `global.hostname` is `portal.ardac.org`.
- `global.revproxyArn` points to the production ACM certificate ARN committed in the values file.
- `global.pdb` is enabled with `global.minAvailable: 1`.
- `global.topologySpread` is enabled with hard hostname spread using `whenUnsatisfiable: DoNotSchedule`.
- Critical user-facing services currently run with elevated replicas, including `ambassador`, `aws-es-proxy`, `fence`, `portal`, and `revproxy`.
- The portal image is `bearbbhao/ardac-portal:1_3_4`.
- Several core Gen3 service images use the `2026.03` tag.

Treat `values.yaml` as the main GitOps source for Gen3 workload behavior. After a change merges to `main`, Argo CD consumes the values repo through the `$values` source configured in the app manifest.

## Karpenter and Cluster-Level Resources

The production cluster-level values file is `ardac1prd/cluster-level-resources/cluster-values.yaml`.

Important current settings:

- Karpenter is managed through the upstream `cluster-level-resources` chart.
- The default NodePool is Spot-only.
- The default NodePool uses `consolidationPolicy: "WhenEmpty"` to reduce voluntary disruption.
- The default NodePool excludes `nano`, `micro`, `small`, and `medium` instance sizes.
- External Karpenter chart values are supplied through `ardac1prd/cluster-values/karpenter.yaml`.
- `ardac1prd/cluster-values/karpenter.yaml` sets the service account role annotation and `settings.interruptionQueue: ardac1prd-ardac1prd`.

Karpenter changes deserve extra validation. A NodePool policy change can cause immediate drift replacement, so plan pause points before changing live Karpenter policy.

## Fluent Bit and Usage Logs

Production Fluent Bit values are in `ardac1prd/fluentbit/values.yaml`.

Current routing model:

- Tail Kubernetes logs.
- Re-tag all `ardac-anagine` namespace logs to `anagine.all` for CloudWatch.
- Fork a copy to `anagine.filtered`.
- Filter the OpenSearch path to records containing `USAGE_LOG:`.
- Parse the prefixed usage log and inner JSON payload into top-level fields.
- Send filtered records to OpenSearch index `anagine-logs`.

This keeps broad Anagine logs in CloudWatch while sending structured usage events to OpenSearch for aggregation.

## ALB Rules

Raw ALB ingress rules can be managed through Argo CD under `ardac1prd/new.portal.ardac.org/manifests`.

The current redirect manifest:

- Joins the existing ALB group with `alb.ingress.kubernetes.io/group.name: ardac1prd`.
- Handles host `new.portal.ardac.org`.
- Redirects to `portal.ardac.org`.
- Uses `HTTP_302` so the compatibility hostname can be repurposed later.

Use GitOps-managed Kubernetes `Ingress` resources for ALB listener-rule changes. Do not manually edit ALB rules unless the user explicitly chooses an emergency live change.

## Terraform

`terraform/fluentbit-opensearch` is a standalone module with an S3 backend configured at `terraform init` time. It creates or manages:

- Fluent Bit CloudWatch log group
- CloudWatch and OpenSearch IAM policies
- Fluent Bit IRSA role
- OpenSearch domain access policy

This module manages the full OpenSearch domain access policy, so `opensearch_existing_principals` must include every principal that should keep access.

## Validation Surfaces

Use the narrowest validation that proves the change:

- YAML files: `yamllint <file>`
- Raw Kubernetes manifests: `kubectl apply --dry-run=client --validate=false -f <file>`
- Helm values: render the chart source referenced by the Argo CD `Application`
- Terraform modules: `terraform fmt -check`, `terraform init -backend=false` when possible, and `terraform validate`
- Git diffs: `git diff --check`

Live validation usually needs `kubectl`, AWS CLI, Helm, and the correct AWS profile or kubeconfig context.

---
type: Runbook
title: Plan and run a Gen3 EKS Kubernetes upgrade
description: Live EKS upgrade procedure for Gen3 deployments with Karpenter, self-managed add-ons, ALB health checks, and stateful workload gates.
tags: [eks, kubernetes, upgrade, karpenter, alb, gen3]
timestamp: 2026-07-09T00:00:00Z
---

# Plan and Run a Gen3 EKS Kubernetes Upgrade

Last reviewed: 2026-07-09

## When To Use

Use this for Gen3 EKS upgrades, especially clusters where:

- workers are managed by Karpenter
- core EKS add-ons are self-managed rather than EKS managed add-ons
- public traffic depends on AWS Load Balancer Controller and instance target groups
- the availability target is near-zero downtime

This runbook is derived from a recent Kubernetes `1.33` to `1.34` upgrade session. Adapt cluster names, profiles, hostnames, and add-on versions to the target environment.

## Key Lessons

- Control-plane upgrade can succeed while worker rotation is still risky.
- Karpenter NodePool policy changes can trigger immediate drift replacement.
- Pause points matter more than speed.
- PDBs with zero allowed disruptions can block or complicate node rotation.
- Verify whether in-cluster stateful services are actually used before scaling or deleting them.
- ALB target health is a practical external gate during rotation.

## Preflight

1. Confirm the operational source of truth.

   Some Gen3 environments may be operated from a VM, live cluster commands, Terraform, or GitOps. Do not assume this repo is the only source of truth for the target cluster.

2. Confirm AWS and Kubernetes access.

   ```bash
   aws sts get-caller-identity --profile <profile>
   aws eks describe-cluster --profile <profile> --name <cluster-name>
   kubectl get --raw /readyz
   kubectl get nodes -o wide
   ```

3. Check EKS upgrade insights and target version availability.

   ```bash
   aws eks list-insights --profile <profile> --cluster-name <cluster-name>
   aws eks describe-cluster --profile <profile> --name <cluster-name>
   ```

4. Inventory add-ons and controllers.

   ```bash
   kubectl -n kube-system get ds,deploy
   kubectl -n karpenter get deploy
   helm list -A
   kubectl get crd | grep karpenter
   ```

   Record:

   - VPC CNI image
   - kube-proxy image
   - CoreDNS image
   - AWS Load Balancer Controller version
   - Karpenter chart and app version
   - external-secrets and Argo CD versions if they are part of the environment

5. Inventory Karpenter.

   ```bash
   kubectl get nodepool -o yaml
   kubectl get ec2nodeclass -o yaml
   kubectl get nodeclaims -o wide
   kubectl get nodes -L karpenter.sh/nodepool,node.kubernetes.io/instance-type,karpenter.sh/capacity-type
   ```

6. Inventory workload blockers.

   ```bash
   kubectl get pdb -A
   kubectl get statefulset -A
   kubectl get pvc -A
   kubectl get pods -A --field-selector=status.phase!=Running
   ```

   Treat singleton databases, Elasticsearch, and PDBs with `0` allowed disruptions as planned pause points.

7. Check public traffic health.

   ```bash
   kubectl get ingress -A
   kubectl get svc -A
   aws elbv2 describe-target-health --profile <profile> --target-group-arn <target-group-arn>
   ```

## Recommended Sequence

1. Stabilize the cluster before changing versions.

   - Remove or explicitly ignore stale failed pods.
   - Confirm deployments, daemonsets, statefulsets, and ALB targets are healthy.
   - Confirm EKS upgrade insights are passing.
   - Confirm Karpenter can create replacement capacity.

2. Decide whether to pause Karpenter disruption before policy changes.

   If you plan to change NodePool requirements, AMI selection, consolidation, or budgets during the upgrade, pause or tightly control Karpenter disruption first. A NodePool patch can create drift and start replacement immediately.

3. Upgrade the EKS control plane.

   ```bash
   aws eks update-cluster-version --profile <profile> --name <cluster-name> --kubernetes-version <target-version>
   aws eks describe-update --profile <profile> --name <cluster-name> --update-id <update-id>
   ```

   Poll until successful. Then verify:

   ```bash
   aws eks describe-cluster --profile <profile> --name <cluster-name>
   kubectl version
   kubectl get --raw /readyz
   kubectl get deploy,ds,statefulset -A
   ```

4. Re-check workloads and ALB health before add-on or node changes.

5. Upgrade self-managed add-ons one at a time.

   Typical order:

   - kube-proxy
   - VPC CNI (`aws-node`)
   - CoreDNS
   - Karpenter, if required for target Kubernetes compatibility
   - AWS Load Balancer Controller only if compatibility requires it

   After each component, wait for full readiness and re-check ALB target health.

6. Apply Karpenter NodePool policy changes only with a drift plan.

   If restricting node sizes, use:

   ```yaml
   - key: karpenter.k8s.aws/instance-size
     operator: NotIn
     values:
       - nano
       - micro
       - small
       - medium
   ```

   Do not assume this waits until you are ready. Watch `NodeClaims` immediately after the patch.

7. Rotate workers one at a time.

   For each old node:

   - Confirm replacement capacity exists and is Ready.
   - Confirm replacement kubelet version matches the target.
   - Confirm `aws-node` and `kube-proxy` are running on the replacement.
   - Drain one old node while respecting PDBs.
   - Confirm Gen3 deployments recover.
   - Confirm ALB targets recover.

8. Handle singleton stateful workloads separately.

   If a node hosts PostgreSQL, Elasticsearch, or another singleton:

   - confirm whether the service is actually used
   - confirm persistent data location
   - get user approval before scaling, deleting, or forcing a drain

   In the GAIPO session, the in-cluster `gen3-postgresql` pod was verified as unused before scaling to `0`; the application database credentials pointed to Aurora and the local Postgres had no user tables or PVC.

## Final Validation

```bash
aws eks describe-cluster --profile <profile> --name <cluster-name>
kubectl get nodes -o wide
kubectl get nodeclaims -o wide
kubectl get deploy,ds,statefulset -A
kubectl get pdb -A
kubectl get pods -A --field-selector=status.phase!=Running
aws elbv2 describe-target-health --profile <profile> --target-group-arn <target-group-arn>
```

Confirm:

- control plane is on the target version
- every worker kubelet is on the target-compatible version
- no old Karpenter NodeClaims remain unless intentionally deferred
- no excluded instance sizes are used by new nodes
- ALB targets are healthy
- Gen3 user-facing deployments are ready
- no new sustained crash loops, image pull failures, or failed rollouts exist

## Stop Conditions

Pause and ask the user when:

- Karpenter starts unexpected drift replacement
- ALB targets become unhealthy or stuck draining
- a singleton stateful workload blocks a node
- new nodes come up on the old kubelet version
- Karpenter cannot provision replacement capacity
- EKS update status is anything other than normal in-progress or successful

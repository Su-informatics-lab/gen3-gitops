---
type: Runbook
title: Investigate and reduce Karpenter disruption
description: Incident investigation and mitigation for Karpenter-managed Gen3 EKS clusters.
tags: [karpenter, eks, nodepool, disruption, spot, gen3]
timestamp: 2026-07-09T00:00:00Z
---

# Investigate and Reduce Karpenter Disruption

Last reviewed: 2026-07-09

## When To Use

Use this when a Gen3 environment appears to have had node churn, portal downtime, pods stuck pending, or ALB target churn in a Karpenter-managed EKS cluster.

This runbook is based on recent `ardac1prd` incidents involving voluntary Karpenter consolidation, Spot churn, small instance pod limits, and missing or incomplete interruption-queue wiring.

## Source Of Truth

- `ardac1prd/cluster-level-resources/cluster-values.yaml`
- `ardac1prd/cluster-values/karpenter.yaml`
- `ardac1prd/portal.ardac.org/values.yaml`

For `ardac1prd`, use AWS profile `ardac-portal-tf` unless the user gives a different profile.

## Current Mitigations In The Repo

The current production config already includes the main mitigations from recent work:

- default NodePool uses `consolidationPolicy: "WhenEmpty"`
- default NodePool excludes `nano`, `micro`, `small`, and `medium`
- Karpenter Helm settings include `interruptionQueue: ardac1prd-ardac1prd`
- global Gen3 PDBs are enabled with `minAvailable: 1`
- hard hostname topology spread is enabled
- critical services have elevated replica counts

## Incident Investigation

1. Convert the reported local time to UTC.

   Be explicit about Eastern Standard Time versus Eastern Daylight Time. For example, June dates in New York are EDT, not EST.

2. Capture current Kubernetes health.

   ```bash
   kubectl get deploy,statefulset,daemonset -A
   kubectl get pods -A -o wide
   kubectl get pdb -A
   kubectl get nodes -o wide
   kubectl get nodeclaims -o wide
   kubectl get nodepool -o yaml
   ```

3. Check Karpenter logs around the incident.

   ```bash
   kubectl -n karpenter logs deploy/karpenter --since-time=<utc-start> --timestamps
   ```

   Look for:

   - `underutilized`
   - `drifted`
   - `expired`
   - `interruption`
   - `terminating`
   - failed scheduling or daemonset overhead messages

4. Check AWS CloudTrail for Karpenter and EC2 activity.

   ```bash
   aws cloudtrail lookup-events --profile ardac-portal-tf --lookup-attributes AttributeKey=EventName,AttributeValue=TerminateInstances --start-time <utc-start> --end-time <utc-end>
   aws cloudtrail lookup-events --profile ardac-portal-tf --lookup-attributes AttributeKey=EventName,AttributeValue=RunInstances --start-time <utc-start> --end-time <utc-end>
   ```

5. Distinguish the failure mode.

   - Voluntary consolidation: Karpenter logs show `underutilized` or similar reasons and CloudTrail shows Karpenter initiating termination.
   - Spot interruption or EC2-side loss: Karpenter cleanup calls encounter instances already in `terminated` state, or replacement Spot nodes are short-lived.
   - Drift replacement: a NodePool, EC2NodeClass, AMI, or cluster version change causes Karpenter to replace nodes.
   - Pod-limit pressure: nodes are Ready but daemonsets or workloads cannot schedule because instance pod limits are too low.

6. Check interruption handling.

   ```bash
   kubectl -n karpenter get deploy karpenter -o yaml
   kubectl -n karpenter logs deploy/karpenter --tail=200
   ```

   Confirm the rendered Karpenter deployment receives the interruption queue setting. In this repo, `ardac1prd/cluster-values/karpenter.yaml` should set:

   ```yaml
   settings:
     interruptionQueue: ardac1prd-ardac1prd
   ```

7. Check SQS permissions if interruption handling is configured but logs show access failures.

   The relevant queue for `ardac1prd` is `ardac1prd-ardac1prd`. Recent operations found the queue and EventBridge rules existed, but the Karpenter IAM policy needed SQS read/delete permissions for the real queue ARN.

## Mitigation Pattern

Use the least invasive mitigation that matches the incident:

- For voluntary consolidation of non-empty nodes, set default NodePool consolidation to `WhenEmpty`.
- For pod-limit pressure, exclude small instance sizes. Current production excludes `nano`, `micro`, `small`, and `medium`.
- For Spot churn, enable and verify interruption-queue handling.
- For critical portal availability, increase replicas for traffic-path services and require hard hostname spread.
- For stronger availability, consider a targeted On-Demand NodePool for critical services, but treat that as a separate cost and scheduling decision.

## Validation Before Merge

Render the affected charts and inspect the output:

- cluster-level chart renders the default NodePool policy
- Karpenter deployment renders the interruption queue setting
- Gen3 chart renders expected replicas
- Gen3 chart renders PDBs and hostname topology spread

Also run:

```bash
git diff --check
```

## Validation After Argo Sync

```bash
kubectl get nodepool default -o yaml
kubectl get nodeclaims -o wide
kubectl -n karpenter logs deploy/karpenter --tail=200
kubectl get deploy -n default
kubectl get pods -n default -o wide
kubectl get pdb -n default
```

Confirm:

- Karpenter is not attempting non-empty consolidation unless expected.
- New nodes do not use excluded sizes.
- Critical deployments have the intended replica counts.
- Replicas are spread across distinct hostnames where possible.
- ALB targets return to healthy.
- Fluent Bit schedules on new nodes.

## Emergency Pause

If a live NodePool change triggers unexpected drift replacement:

1. Pause further Karpenter disruption by setting a NodePool disruption budget of `nodes: "0"` if appropriate for the installed Karpenter version.
2. Re-check workloads, ALB targets, and nodes already marked for deletion.
3. Do not force-drain nodes hosting singleton stateful workloads unless the user explicitly approves the risk.
4. Consider scaling the Karpenter controller to `0` only as a deliberate emergency stop, then document exactly how to resume.

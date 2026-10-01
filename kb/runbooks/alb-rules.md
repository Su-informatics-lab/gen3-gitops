---
type: Runbook
title: Manage ALB listener rules through GitOps
description: GitOps procedure for ALB redirects, fixed responses, and listener-rule validation.
tags: [alb, ingress, aws-load-balancer-controller, gitops, redirect]
timestamp: 2026-07-09T00:00:00Z
---

# Manage ALB Listener Rules Through GitOps

Last reviewed: 2026-07-09

## When To Use

Use this when adding, changing, or validating AWS ALB listener behavior for a Gen3 hostname, including:

- redirecting a compatibility hostname
- blocking a specific path or method
- returning a fixed response from the ALB

Use GitOps-managed Kubernetes `Ingress` resources with AWS Load Balancer Controller. Avoid manual ALB edits unless the user explicitly chooses an emergency live change.

## Source Of Truth

Current production redirect:

- app: `ardac1prd/new.portal.ardac.org/app.yaml`
- manifest: `ardac1prd/new.portal.ardac.org/manifests/ingress.yaml`

The current manifest joins ALB group `ardac1prd` and redirects `new.portal.ardac.org` to `portal.ardac.org` with `HTTP_302`.

## Hostname Redirect Pattern

Use a redirect, not a CNAME-only solution, when Gen3 should remain canonical on one hostname. A CNAME can point traffic at the ALB, but it does not change the browser hostname, which can affect ingress host rules, TLS, OAuth callbacks, cookies, and generated app URLs.

Key annotations:

```yaml
alb.ingress.kubernetes.io/actions.redirect-to-portal: '{"Type":"redirect","RedirectConfig":{"Protocol":"HTTPS","Port":"443","Host":"portal.ardac.org","Path":"/#{path}","Query":"#{query}","StatusCode":"HTTP_302"}}'
alb.ingress.kubernetes.io/group.name: ardac1prd
```

Use `HTTP_302` when the source hostname may be reused later. Use `HTTP_301` only for a permanent redirect.

## Fixed-Response Block Pattern

For API key creation blocking, recent work used the ALB because the portal sends:

```text
POST /user/credentials/cdis/
```

The ALB can robustly block key creation with a fixed response. A friendly portal UI still requires portal code support because the request is made through JavaScript, not a normal browser navigation.

When implementing a fixed response:

- match host `portal.ardac.org`
- match method `POST`
- match exact paths `/user/credentials/cdis/` and `/user/credentials/cdis`
- return a machine-readable JSON body
- use a higher-priority rule than the normal revproxy forwarding rule

AWS Load Balancer Controller supports action and condition annotations. Keep the action backend name aligned with the annotation suffix.

## Procedure

1. Inspect the current app and manifest.

   ```powershell
   Get-Content ardac1prd\new.portal.ardac.org\app.yaml
   Get-Content ardac1prd\new.portal.ardac.org\manifests\ingress.yaml
   ```

2. Confirm the live ALB is Kubernetes-owned before changing listener behavior.

   ```powershell
   aws elbv2 describe-load-balancers --profile ardac-portal-tf
   aws elbv2 describe-listeners --profile ardac-portal-tf --load-balancer-arn <alb-arn>
   aws elbv2 describe-rules --profile ardac-portal-tf --listener-arn <listener-arn>
   ```

   Look for AWS Load Balancer Controller stack tags and existing rules for the target host.

3. Add or edit the Kubernetes `Ingress` manifest in the raw manifest app path.

   Prefer reusing the existing synced path when the change belongs to the same ALB compatibility surface. Create a new Argo CD app only when the ownership boundary is genuinely different and bootstrap is understood.

4. Validate locally.

   ```powershell
   yamllint ardac1prd\new.portal.ardac.org\manifests\ingress.yaml
   kubectl apply --dry-run=client --validate=false -f ardac1prd\new.portal.ardac.org\manifests\ingress.yaml
   git diff --check
   ```

5. After merge and Argo sync, verify ALB behavior.

   ```powershell
   aws elbv2 describe-rules --profile ardac-portal-tf --listener-arn <listener-arn>
   curl.exe -I https://new.portal.ardac.org/
   ```

   For a fixed-response block:

   ```powershell
   curl.exe -i -X POST https://portal.ardac.org/user/credentials/cdis/
   ```

## Validation Expectations

For the `new.portal.ardac.org` redirect:

- no second ALB is created
- the existing ALB gains a listener rule for `new.portal.ardac.org`
- response status is `302`
- path and query are preserved
- `portal.ardac.org` still forwards to `revproxy-service`

For an API key fixed response:

- `POST /user/credentials/cdis/` returns the fixed response
- `GET` or unrelated Fence paths remain unaffected
- no key is created
- portal UI behavior is tested separately because existing upstream portal failure handling may not show the ALB response cleanly

## Rollback

Rollback is a GitOps revert:

1. Revert the manifest change.
2. Merge to `main`.
3. Let Argo CD sync.
4. Confirm the ALB listener rule disappears.

Avoid deleting ALB rules manually unless there is an emergency and the user approves live drift.

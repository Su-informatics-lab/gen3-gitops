---
type: Runbook
title: Update Anagine usage-log routing in Fluent Bit
description: Procedure for routing structured Anagine USAGE_LOG records through Fluent Bit into OpenSearch.
tags: [fluentbit, anagine, opensearch, logs, usage-log]
timestamp: 2026-07-09T00:00:00Z
---

# Update Anagine Usage-Log Routing In Fluent Bit

Last reviewed: 2026-07-09

## When To Use

Use this when Anagine usage log format changes, OpenSearch aggregation fields need adjustment, or Fluent Bit parsing/routing for `USAGE_LOG:` records needs validation.

The current production implementation is in `ardac1prd/fluentbit/values.yaml`.

## Current Routing Model

For `ardac1prd`:

- all `ardac-anagine` namespace logs are re-tagged to `anagine.all`
- `anagine.all` is sent to CloudWatch
- a copy is forked to `anagine.filtered`
- `anagine.filtered` is narrowed to records containing `USAGE_LOG:`
- parser filters extract the JSON payload and parse it into top-level fields
- parsed usage records are sent to OpenSearch index `anagine-logs`

This preserves broad logs in CloudWatch while keeping the OpenSearch index focused on structured usage events.

## Procedure

1. Confirm scope.

   Recent production work intentionally changed only `ardac1prd`; do not change `ardac1dmo` unless the user asks.

2. Inspect the incoming log shape.

   Expected shape:

   ```text
   [timestamp] USAGE_LOG: {"@timestamp":"...","user":"..."}
   ```

   The exact JSON fields can evolve, but `@timestamp` and `user` are important for aggregation.

3. Update `ardac1prd/fluentbit/values.yaml`.

   Preserve these behaviors unless the user asks otherwise:

   - `[SERVICE]` includes both default parsers and custom parser file.
   - `config.customParsers` defines the prefixed-line parser and JSON parser.
   - OpenSearch routing gates on `USAGE_LOG:`.
   - CloudWatch still receives all Anagine logs.
   - OpenSearch receives `anagine.filtered` only.

4. Validate Helm rendering.

   Use the chart version in `ardac1prd/fluentbit/app.yaml`.

   ```bash
   helm template fluent-bit fluent/fluent-bit --version 0.57.5 -f ardac1prd\fluentbit\values.yaml --show-only templates/configmap.yaml
   ```

   If `helm lint` cannot lint a remote chart directly with the pinned version, pull the chart to a temp directory and lint the local copy with the updated values.

5. Run a local parser sanity check when possible.

   At minimum, verify the regex captures the JSON payload and that the payload parses as JSON.

6. Check OpenSearch mapping before deployment when changing fields.

   If a port-forward is available on `localhost:9200`:

   ```bash
   curl -s http://localhost:9200/anagine-logs/_mapping
   curl -s "http://localhost:9200/anagine-logs/_field_caps?fields=@timestamp,user"
   ```

   Desired mapping:

   - `@timestamp`: `date`
   - `user`: `keyword`

7. Add missing mapping fields in place when safe.

   If `user` is absent, add it before deploying the Fluent Bit change so dynamic mapping does not create an unexpected type.

   ```http
   PUT /anagine-logs/_mapping
   {
     "properties": {
       "user": { "type": "keyword" }
     }
   }
   ```

   This is safe when the field is absent. If a field already exists with an incompatible type, plan a reindex or new index instead.

## Validation Before Merge

```bash
helm template fluent-bit fluent/fluent-bit --version 0.57.5 -f ardac1prd\fluentbit\values.yaml --show-only templates/configmap.yaml
git diff --check
```

Also verify:

- `custom_parsers.conf` is rendered
- service config references the custom parser file
- OpenSearch output uses `Match anagine.filtered`
- OpenSearch output writes to `Index anagine-logs`

## Validation After Deploy

```bash
kubectl -n kube-system get pods -l app.kubernetes.io/name=fluent-bit
kubectl -n kube-system logs -l app.kubernetes.io/name=fluent-bit --tail=200
```

Then query OpenSearch:

```bash
curl -s "http://localhost:9200/anagine-logs/_search?size=1&sort=@timestamp:desc"
curl -s "http://localhost:9200/anagine-logs/_field_caps?fields=@timestamp,user"
```

Confirm:

- new records contain top-level `@timestamp`
- new records contain top-level `user`
- both fields are aggregatable
- no sustained Fluent Bit parser errors appear

## Common Pitfalls

- Do not remove the CloudWatch path while narrowing OpenSearch.
- Do not assume OpenSearch mappings update automatically in the desired way.
- Do not apply a mapping change if the field already exists with an incompatible type.
- Do not change demo and production together unless the user explicitly asks.

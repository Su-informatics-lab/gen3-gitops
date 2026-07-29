# ARDAC2 Production Deployment

This directory contains the GitOps configuration for the `ardac2prd` EKS
cluster. During blue/green staging, `new.portal.ardac.org` is the canonical
Gen3 hostname. The supplemental ingress in `load-balancer/` adds
`portal.ardac.org` and `archive.portal.ardac.org` to the same cluster-local
Application Load Balancer.

Before bootstrapping Argo CD, confirm these infrastructure values match outputs from the `ardac2prd` Terraform deployment:

- EKS cluster endpoint (Karpenter `settings.clusterEndpoint`)
- OpenSearch endpoint (Fluent Bit `OPENSEARCH_HOST` and `aws-es-proxy.esEndpoint`)
- Users bucket (Fence `usersync.userYamlS3Path`)
- Audit SQS URL (Audit `server.sqs.url`)

Ensure the Audit and SSJ Dispatcher queues/secrets provisioned by Terraform match what this configuration references (for example, Audit `server.sqs.url` points at an `ardac2prd-*` queue). Do not bootstrap this deployment until the environment-specific queues and corresponding secrets exist.

At production cutover, change `global.hostname` to `portal.ardac.org`, move
`new.portal.ardac.org` into the supplemental alias ingress, and then update
Route 53 separately.

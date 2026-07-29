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

The Audit and SSJ Dispatcher queues must be unique to `ardac2prd`. The current
`gen3-terraform` implementation uses the account-global names `audit` and
`ssjdispatcher`; do not bootstrap this deployment until the Terraform
configuration provides environment-specific queues and secrets.

At production cutover, change `global.hostname` to `portal.ardac.org`, move
`new.portal.ardac.org` into the supplemental alias ingress, and then update
Route 53 separately.

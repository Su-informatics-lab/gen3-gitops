# ARDAC2 Production Deployment

This directory contains the GitOps configuration for the `ardac2prd` EKS
cluster. `portal.ardac.org` is the canonical Gen3 hostname. The supplemental
ingress in `load-balancer/` redirects `new.portal.ardac.org` to the canonical
hostname on the same Application Load Balancer.

Before bootstrapping Argo CD, confirm these infrastructure values match outputs from the `ardac2prd` Terraform deployment:

- EKS cluster endpoint (Karpenter `settings.clusterEndpoint`)
- OpenSearch endpoint (Fluent Bit `OPENSEARCH_HOST` and `aws-es-proxy.esEndpoint`)
- Users bucket (Fence `usersync.userYamlS3Path`)
- Audit SQS URL (Audit `server.sqs.url`)

Ensure the Audit and SSJ Dispatcher queues/secrets provisioned by Terraform match what this configuration references (for example, Audit `server.sqs.url` points at an `ardac2prd-*` queue). Do not bootstrap this deployment until the environment-specific queues and corresponding secrets exist.

Route 53 is managed separately. Both `portal.ardac.org` and
`new.portal.ardac.org` must resolve to the `ardac2prd` Application Load
Balancer. `archive.portal.ardac.org` resolves to the `ardac1prd` Application
Load Balancer.

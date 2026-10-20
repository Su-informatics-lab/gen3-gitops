# ARDAC2 Green Development Deployment

This directory contains the GitOps configuration for the `ardac2prd` EKS
cluster. `new.portal.ardac.org` is the canonical Gen3 hostname. The
supplemental ingress in `load-balancer/` redirects `archive.portal.ardac.org`
to the development hostname on the same Application Load Balancer.

Before bootstrapping Argo CD, confirm these values match the manually managed `ardac2prd` infrastructure:

- EKS cluster endpoint (Karpenter `settings.clusterEndpoint`)
- OpenSearch endpoint (Fluent Bit `OPENSEARCH_HOST` and `aws-es-proxy.esEndpoint`)
- Users bucket (Fence `usersync.userYamlS3Path`)
- Audit SQS URL (Audit `server.sqs.url`)

Ensure the Audit and SSJ Dispatcher queues/secrets provisioned by Terraform match what this configuration references (for example, Audit `server.sqs.url` points at an `ardac2prd-*` queue). Do not bootstrap this deployment until the environment-specific queues and corresponding secrets exist.

Route 53 is managed separately. `portal.ardac.org` resolves to the `ardac1prd`
Application Load Balancer. Both `new.portal.ardac.org` and
`archive.portal.ardac.org` resolve to the `ardac2prd` Application Load
Balancer.

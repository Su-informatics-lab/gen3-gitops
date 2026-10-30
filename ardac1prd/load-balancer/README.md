# ARDaC production load balancer

## API key creation

The `api-key-creation-block` Ingress rejects public API key creation requests
to both the current Fence `/credentials/api` route and the deprecated
`/credentials/cdis` route. The rule matches only `POST` requests to those exact
paths. Existing key listing, deletion, and access-token exchange remain routed
to Fence.

The exception is based on Kubernetes access, not the Gen3 portal-admin role.
A trusted cluster operator can create an exceptional key by port-forwarding to
Fence or by making an in-cluster `POST` request to
`http://fence-service/credentials/api` with the operator's authenticated Fence
session token. Fence creates the key for the user identified by that token.

Treat the returned API key and the session token as secrets. Do not place them
in Git, command history, tickets, or logs. Use an explicit `ardac1prd` Kubernetes
context for any operator procedure.

To roll back the public restriction, revert the supplemental Ingress. Fence and
its database do not require a rollback.

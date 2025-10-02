# gen3-gitops
Terragrunt, Argo, and Kro deployment code for Gen3 environments

## Repository Structure

```
gen3-gitops/
├── terraform/                      # Terraform modules
│   └── jump/                       # Admin jump server module
├── terragrunt/                     # Terragrunt configurations
│   ├── jump/                       # Jump server deployments
│   │   ├── root.hcl               # Root configuration
│   │   ├── .env.example           # Environment variables template
│   │   └── environments/
│   │       ├── example/           # Example deployment
│   │       └── gaipo/             # Gaipo deployment
│   └── commons/                    # Gen3 commons deployments
│       ├── root.hcl               # Root configuration
│       ├── QUICKSTART.md          # Quick start guide
│       └── environments/
│           ├── .env.example       # Environment variables template
│           ├── example/           # Example deployment
│           └── ardac-portal-one/  # ARDAC Portal deployment
├── argocd/                         # ArgoCD configurations
└── LICENSE

```

## Quick Start

### Jump Server (Admin VM)

For deploying Gen3 admin jump servers:

```bash
cd terragrunt/jump/environments/example
terragrunt plan
terragrunt apply
```

See [terragrunt/jump/README.md](terragrunt/jump/README.md) for detailed instructions.

### Gen3 Commons

For deploying full Gen3 commons environments:

```bash
cd terragrunt/commons/environments/example
terragrunt plan
terragrunt apply
```

See [terragrunt/commons/README.md](terragrunt/commons/README.md) for detailed instructions.

## Documentation

- **Jump Server Deployment**: [terragrunt/jump/README.md](terragrunt/jump/README.md)
- **Commons Deployment**: [terragrunt/commons/README.md](terragrunt/commons/README.md)
- **Quick Start Guide**: [terragrunt/commons/QUICKSTART.md](terragrunt/commons/QUICKSTART.md)

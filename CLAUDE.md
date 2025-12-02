# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform/Kubernetes infrastructure-as-code project for deploying cost-optimized Azure AKS clusters with automated SSL certificates and DNS management. The project supports multiple environments across different Azure subscriptions (Microsoft Partner Network and Visual Studio Enterprise) and includes reusable modules for cluster provisioning and application deployments.

## Common Commands

### Environment Initialization and Deployment

```bash
# Initialize Terraform for AKS cluster 1 (mpn-westeu-prod)
pnpm run aks-1:init

# Apply Terraform changes to AKS cluster 1
pnpm run aks-1:apply

# Connect to AKS cluster 1 context
pnpm run aks-1:connect

# Initialize Terraform for AKS cluster 2 (vse-westeu-prod)
pnpm run aks-2:init

# Apply Terraform changes to AKS cluster 2
pnpm run aks-2:apply

# Connect to AKS cluster 2 context
pnpm run aks-2:connect

# Run any terraform command in specific cluster directory
pnpm run aks-1 -- <terraform-command>
pnpm run aks-2 -- <terraform-command>
```

### Monitoring and Management

```bash
# Open Grafana dashboard (port-forward)
pnpm run grafana

# Open Rancher management UI (port-forward)
pnpm run rancher

# Make scripts executable
pnpm run scripts:init
```

### Manual Kubernetes Operations

```bash
# Verify current Kubernetes context
./scripts/verify-kube-context.sh <cluster-name>

# Get cluster credentials manually
az aks get-credentials --resource-group rg-<cluster-name> --name <cluster-name>

# Check ingress external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Check cert-manager status
kubectl get pods -n cert-manager

# View certificate issuers
kubectl get clusterissuer -n cert-manager
```

## Architecture

### Multi-Environment Structure

The project supports multiple AKS environments in separate directories:
- **aks-1-mpn-westeu-prod**: Cost-optimized production cluster on Microsoft Partner Network subscription
- **aks-2-vse-westeu-prod**: Production cluster on Visual Studio Enterprise subscription

Each environment directory contains:
- `provider.tf`: Terraform provider configuration with backend state storage in Azure Storage
- `aks-cluster.tf`: Cluster configuration using the `modules/aks-cluster` module
- Application deployment files (e.g., `app-plausible-v3.tf`)

### Module System

**Core Infrastructure Module** (`modules/aks-cluster/`):
- Creates Azure Resource Group and AKS cluster
- Configures node pools with auto-scaling
- Deploys NGINX Ingress Controller with LoadBalancer service
- Installs cert-manager for SSL certificate management
- Sets up Let's Encrypt certificate issuers (production and staging)
- Automatically sets local kubectl context after cluster creation

**Application Modules**:
- `modules/app-plausible/`: Plausible Analytics deployment with PostgreSQL and ClickHouse
- `modules/app-elastic-stack/`: Elastic Stack deployment
- `modules/persistent-azure-disk-volume/`: Creates Azure Managed Disks as Kubernetes Persistent Volumes

### Terraform Provider Integration

The project uses dynamic provider configuration where Helm and Kubernetes providers use credentials from the AKS cluster being created. This allows seamless deployment of Kubernetes resources immediately after cluster creation.

All providers connect through the `module.aks_cluster.kube_config` output, which provides:
- `host`: Cluster API server endpoint
- `client_certificate`: Base64-encoded client certificate
- `client_key`: Base64-encoded client key
- `cluster_ca_certificate`: Base64-encoded cluster CA certificate

### Kubernetes Context Management

The `null_resource.set_kube_context` in `modules/aks-cluster/aks-cluster.tf` automatically:
1. Extracts kube config from Terraform state
2. Writes it to `~/.kube/config`
3. Sets the current context to the newly created cluster
4. Runs on every `terraform apply` (triggered by timestamp)

This ensures all subsequent kubectl commands and local-exec provisioners target the correct cluster.

### Ingress and Certificate Management

The ingress setup follows this flow:
1. NGINX Ingress Controller creates an Azure LoadBalancer service
2. Azure assigns a public IP to the LoadBalancer
3. `data.external.ingress_external_ip` extracts this IP using kubectl
4. Cloudflare DNS records point domains to this IP
5. cert-manager with Let's Encrypt issues SSL certificates using DNS-01 challenge via Cloudflare API

### Application Deployment Pattern

Applications use a consistent pattern:
1. Create namespace and persistent Azure disks
2. Deploy using Helm charts with custom values
3. Create Ingress resources with TLS and cert-manager annotations
4. Cloudflare DNS records point to cluster LoadBalancer IP

Example from `modules/app-plausible/`:
- Creates Azure Managed Disks for PostgreSQL and ClickHouse
- Creates Kubernetes PVs and PVCs referencing those disks
- Deploys Plausible via Helm chart with secrets and environment variables
- Ingress uses `cert-manager.io/cluster-issuer: letsencrypt-prod` annotation

## Required Variables

### Provider Configuration (in environment directories)
- `azure_subscription_id`: Azure subscription ID
- `cloudflare_api_token`: Cloudflare API token with DNS and Tunnel permissions
- `cloudflare_zone_id`: Cloudflare zone ID for DNS records

### Cluster Configuration
- `azure_cluster_name`: Name of the AKS cluster (defaults set in each environment)
- `letsencrypt_email`: Email for Let's Encrypt certificate registration

### Application-Specific Variables
For Plausible deployments:
- `plausible_dns`: Domain name for the Plausible instance
- `google_client_id`: (optional) Google OAuth integration
- `google_client_secret`: (optional) Google OAuth integration
- `postgresql_restore_snapshot_id`: (optional) Azure snapshot ID for database restore
- `clickhouse_restore_snapshot_id`: (optional) Azure snapshot ID for database restore

## Azure Resource Naming Convention

Resources follow the pattern: `{resourceType}-{workload/app}-{subscription}-{environment}-{region}-{instance}`

Examples:
- `aks-1-mpn-westeu-prod`: AKS cluster on MPN subscription in West Europe
- `rg-aks-1-mpn-westeu-prod`: Resource group for that cluster
- `rg-nodes-aks-1-mpn-westeu-prod`: Node resource group managed by AKS

Subscription abbreviations:
- `mpn`: Microsoft Partner Network
- `vse`: Visual Studio Enterprise

## Terraform State Management

State is stored in Azure Storage Accounts. Each environment has a backend configuration in `provider.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-provisioning-<subscription>"
  storage_account_name = "stprovisioning<subscription>"
  container_name       = "tfstate"
  key                  = "<cluster-name>"
}
```

Ensure these storage accounts and containers exist before running `terraform init`.

## Cost Optimization Details

The `aks-1-mpn-westeu-prod` configuration is optimized for cost:
- VM size: `Standard_B2s` (burstable, 2 vCPU, 4GB RAM)
- OS disk: 30GB Ephemeral (included in VM price, no extra storage cost)
- Auto-scaling: 1-1 nodes (can be increased as needed)
- Max pods per node: 40
- Outbound connectivity: LoadBalancer mode (~$53/month total)

The 30GB ephemeral disk limit means container images must be managed carefully. Application data is stored on separate Azure Managed Disks created by the persistent volume module.

## External Service Integration

### Cloudflare
- DNS record creation for application domains
- API token must have Zone DNS Edit and Account Cloudflare Tunnel Edit permissions
- Records are created with `proxied = false` to expose real IPs for Let's Encrypt validation

### Let's Encrypt
- Free SSL certificates via cert-manager
- Two ClusterIssuers created: `letsencrypt-prod` and `letsencrypt-staging`
- Uses DNS-01 challenge with Cloudflare DNS provider
- Certificates automatically renewed before expiry

## Helm Chart Repositories

The project uses these external Helm repositories:
- cert-manager: `https://charts.jetstack.io`
- ingress-nginx: `https://kubernetes.github.io/ingress-nginx`
- plausible: `https://imio.github.io/helm-charts`

Custom charts are in `helm-charts/` directory (e.g., `letsencrypt-cert-issuer`).

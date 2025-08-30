# Cloudflare Tunnel Infrastructure Module

This Terraform module creates the Cloudflare Tunnel infrastructure components using Cloudflare's Zero Trust platform. It provisions the tunnel registration and configuration in Cloudflare's network, which enables secure connectivity between your services and Cloudflare's edge without requiring public IP addresses.

## Features

- Creates Cloudflare Zero Trust Tunnel with auto-generated credentials
- Configures tunnel ingress rules for traffic routing
- Generates secure tunnel secret automatically
- Supports TLS verification bypass for internal services
- Provides tunnel CNAME for DNS configuration
- Integrates with Cloudflare's global edge network

## How It Works

This module creates the **server-side** tunnel infrastructure in Cloudflare's network:

1. **Tunnel Registration**: Registers a new tunnel with Cloudflare Zero Trust
2. **Credential Generation**: Creates secure tunnel credentials automatically  
3. **Ingress Configuration**: Defines how traffic should be routed to your services
4. **CNAME Provision**: Provides the tunnel endpoint for DNS records

The tunnel client (`cloudflared`) running in your cluster connects to this infrastructure.

## Usage

### Basic Usage

```hcl
module "cloudflare_tunnel" {
  source = "../../../modules/cloudflare/tunnel"
  
  account_id      = var.cloudflare_account_id
  tunnel_name     = "${var.cluster_name}-tunnel"
  ingress_service = "https://ingress-nginx-controller.ingress-nginx.svc.cluster.local"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `account_id` | Cloudflare account ID | `string` | n/a | yes |
| `tunnel_name` | Name of the Cloudflare tunnel | `string` | n/a | yes |
| `ingress_service` | Kubernetes service URL for ingress routing | `string` | n/a | yes |
| `api_token` | Cloudflare API token | `string` | n/a | no |

### Variable Details

#### `account_id`
- **Format**: Cloudflare account ID (32-character hex string)
- **Location**: Found in Cloudflare dashboard → Account → Account ID

#### `tunnel_name`
- **Purpose**: Human-readable name for the tunnel in Cloudflare dashboard
- **Naming**: Use descriptive names like `production-cluster-tunnel`
- **Uniqueness**: Must be unique within your Cloudflare account

#### `ingress_service`
- **Format**: Full service URL with protocol and port
- **Example**:
  - `https://ingress-nginx-controller.ingress-nginx.svc.cluster.local`
- **Purpose**: Defines where tunnel traffic gets routed in your cluster

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `tunnel_id` | The ID of the Cloudflare tunnel | No |
| `tunnel_name` | The name of the Cloudflare tunnel | No |
| `tunnel_cname` | The CNAME of the Cloudflare tunnel | No |
| `tunnel_secret` | The tunnel secret credentials | Yes |

## What Gets Created

### Cloudflare Resources

1. **Zero Trust Tunnel**: The main tunnel registration in Cloudflare
2. **Tunnel Configuration**: Ingress rules defining traffic routing
3. **Tunnel Secret**: Auto-generated 32-character secure credentials

### Generated Components

- **Tunnel CNAME**: `{tunnel-id}.cfargotunnel.com` for DNS records
- **Tunnel Credentials**: Base64-encoded secret for client authentication
- **Ingress Rules**: Configuration for routing all traffic to your service


## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Internet      │───▶│  Cloudflare Edge │───▶│  Tunnel (this mod)  │
│   Traffic       │    │    Network       │    │   Infrastructure    │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                           │
                                                           ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│  Application    │◀───│ Ingress          │◀───│   Cloudflared       │
│   Services      │    │ Controller       │    │    Client           │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
```

## Important Notes

- Tunnel credentials are auto-generated and sensitive
- The tunnel CNAME is used for DNS record creation
- Ingress service should be reachable from within the cluster
- Changes to ingress configuration require tunnel restart
- Multiple tunnels can share the same ingress service

## Related Modules

- `helm/cloudflared`: Deploys tunnel client in Kubernetes cluster
- `cloudflare/dns-record`: Creates DNS records pointing to tunnel
- `helm/ingress-nginx`: Target ingress controller for tunnel traffic
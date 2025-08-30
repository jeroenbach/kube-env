# Cloudflared Helm Module

This Terraform module deploys Cloudflared (Cloudflare Tunnel client) using the official Cloudflare Helm chart. It creates a secure tunnel between your Kubernetes cluster and Cloudflare's edge network, eliminating the need for public IP addresses or open firewall ports.

## Features

- Deploys official Cloudflare Tunnel Helm chart
- Securely connects cluster services to Cloudflare's edge network
- No public IP addresses or open firewall ports required
- Configurable replica count for high availability
- Custom postrender script to remove hardcoded 404 service
- Automatic deployment readiness checking
- Routes all traffic to specified ingress service

## How Cloudflare Tunnel Works

Cloudflare Tunnel creates a secure, outbound-only connection from your cluster to Cloudflare's edge network. This allows you to expose services without:
- Public IP addresses
- Open inbound firewall ports
- Load balancers with external IPs
- Complex network security configurations

## Usage

### Basic Usage

```hcl
module "cloudflared" {
  source = "../../../modules/helm/cloudflared"

  account_id         = "your-cloudflare-account-id"
  tunnel_id          = "your-tunnel-id"
  tunnel_name        = "my-cluster-tunnel"
  tunnel_credentials = base64encode("your-tunnel-credentials")
  ingress_service    = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
}
```

### Usage with High Availability

```hcl
module "cloudflared" {
  source = "../../../modules/helm/cloudflared"

  account_id         = var.cloudflare_account_id
  tunnel_id          = module.cloudflare_tunnel.tunnel_id
  tunnel_name        = module.cloudflare_tunnel.tunnel_name
  tunnel_credentials = module.cloudflare_tunnel.tunnel_secret
  ingress_service    = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
  replica_count      = 3

  depends_on = [
    module.ingress_nginx,
    module.cloudflare_tunnel
  ]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `account_id` | Cloudflare account ID | `string` | n/a | yes |
| `tunnel_id` | Cloudflare tunnel ID | `string` | n/a | yes |
| `tunnel_name` | Cloudflare tunnel name | `string` | n/a | yes |
| `tunnel_credentials` | Base64-encoded tunnel credentials (sensitive) | `string` | n/a | yes |
| `ingress_service` | Target service name for ingress routing | `string` | `ingress-nginx-controller.ingress-nginx.svc.cluster.local:80` | no |
| `replica_count` | Number of pod replicas for high availability | `number` | `1` | no |

### Variable Details

#### `tunnel_credentials`
- **Format**: Base64-encoded JSON credentials from Cloudflare Tunnel creation
- **Sensitive**: Marked as sensitive to prevent logging
- **Source**: Obtained when creating tunnel via Cloudflare dashboard or API

#### `ingress_service`  
- **Purpose**: Defines where tunnel traffic should be routed within the cluster
- **Default**: Routes to NGINX ingress controller on port 80
- **Format**: `protocol://service-name.namespace.svc.cluster.local:port`

#### `replica_count`
- **Range**: 1-10 replicas (validated)
- **Purpose**: High availability and load distribution
- **Recommendation**: Use 2+ replicas for production workloads

## Outputs

This module does not provide any outputs.

## What Gets Deployed

The module deploys the following resources:

- **Namespace**: `cloudflared` (auto-created)
- **Deployment**: Cloudflared pods running the tunnel client
- **ConfigMap**: Tunnel configuration with ingress rules
- **Secret**: Tunnel credentials (from provided variables)

## Custom Configuration

### Postrender Hook
The module includes a custom postrender script that:
- Removes the hardcoded `- service: http_status:404` line from the tunnel configuration
- Allows wildcard hostname routing to work properly
- Enables all traffic to be routed to your ingress controller

### Ingress Rules
The tunnel is configured to route all traffic to the specified `ingress_service`. This creates a simple tunnel configuration:

```yaml
ingress:
  - service: http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80
```

## Traffic Flow

```
Internet → Cloudflare Edge → Cloudflare Tunnel → Cloudflared Pods → Ingress Controller → Application Services
```

1. **Internet Traffic**: Reaches Cloudflare's edge network via your domain
2. **Cloudflare Processing**: SSL termination, DDoS protection, caching
3. **Tunnel Transport**: Secure tunnel to your Cloudflared pods
4. **Cluster Routing**: Traffic routed to ingress controller
5. **Service Discovery**: Ingress routes to appropriate application services

## Benefits

### Security
- No public IP addresses exposed
- No inbound firewall rules required
- Traffic encrypted through Cloudflare's network
- Built-in DDoS protection

### Cost Efficiency  
- No need for Azure Load Balancer external IPs
- Reduced networking costs
- Simplified security group management

### Reliability
- Cloudflare's global edge network
- Automatic failover between tunnel replicas
- Built-in health checking and recovery

## Monitoring and Troubleshooting

### Check Deployment Status
```bash
kubectl get deployment -n cloudflared
kubectl describe deployment cloudflared-cloudflare-tunnel -n cloudflared
```

### View Logs
```bash
kubectl logs -n cloudflared deployment/cloudflared-cloudflare-tunnel
```

## Important Notes

- Tunnel credentials are sensitive and stored securely in Kubernetes secrets
- The postrender hook modifies the default chart behavior for better wildcard support
- Multiple replicas provide redundancy but share the same tunnel connection
- DNS records must point to your Cloudflare Tunnel CNAME (managed separately)

## Related Modules

- `cloudflare/tunnel`: Creates the tunnel infrastructure in Cloudflare
- `ingress-nginx`: NGINX ingress controller (target for tunnel traffic)
- `cloudflare/dns-record`: DNS records pointing to tunnel CNAME
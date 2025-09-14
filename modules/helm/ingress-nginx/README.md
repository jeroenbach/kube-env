# NGINX Ingress Controller Helm Module

This Terraform module deploys the NGINX Ingress Controller using Helm to provide ingress capabilities for Kubernetes clusters. It supports both LoadBalancer and ClusterIP service types for different deployment scenarios.

## Features

- Deploys official NGINX Ingress Controller Helm chart
- Configurable service type (LoadBalancer, ClusterIP, NodePort)
- Azure-optimized health probe configuration
- Automatic external IP retrieval for LoadBalancer services
- Waits for service readiness before completion
- Optimized traffic policy for LoadBalancer services

## Usage

### Basic Usage (LoadBalancer)

```hcl
module "ingress_nginx" {
  source = "../../modules/helm/ingress-nginx"
  
  service_type = "LoadBalancer"
}
```

### Usage with ClusterIP (for Cloudflare Tunnel)

```hcl
module "ingress_nginx" {
  source = "../../modules/helm/ingress-nginx"
  
  service_type = "ClusterIP"
}
```


## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `service_type` | The service type for the ingress-nginx controller | `string` | `"LoadBalancer"` | no |

### Service Type Options

- **LoadBalancer**: Exposes the ingress controller via Azure Load Balancer with external IP
- **ClusterIP**: Internal cluster access only (suitable for Cloudflare Tunnel setups)

## Outputs

| Name | Description |
|------|-------------|
| `external_ip` | The external IP address of the LoadBalancer service (null for ClusterIP/NodePort) |

## Behavior

### LoadBalancer Mode
- Creates Azure Load Balancer with external IP
- Sets `externalTrafficPolicy: Local` for optimal performance
- Configures Azure health probe path (`/healthz`)
- Waits for external IP assignment before completion

### ClusterIP Mode  
- Creates internal-only service
- No external IP assigned
- Suitable for use with Cloudflare Tunnel or other ingress solutions

### NodePort Mode
- Exposes service on each node's IP
- Accessible via `<NodeIP>:<NodePort>`

## Azure Integration

The module includes Azure-specific optimizations:

- **Health Probe**: Configures `/healthz` endpoint for Azure Load Balancer health checks
- **Traffic Policy**: Uses `Local` external traffic policy to preserve client IP
- **Load Balancer Annotations**: Optimized for Azure Load Balancer integration

## Dependencies

- Kubernetes cluster with appropriate RBAC permissions
- Helm provider configured and authenticated
- For LoadBalancer: Azure Load Balancer capability in the cluster

## Important Notes

- The module waits up to 15 minutes for the service to become ready
- External IP assignment for LoadBalancer services may take several minutes
- ClusterIP services will return `null` for `external_ip` output
- The controller is deployed in the `ingress-nginx` namespace (auto-created)
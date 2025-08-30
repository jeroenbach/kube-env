# Azure AKS Cluster Module

This Terraform module creates a comprehensive Azure Kubernetes Service (AKS) cluster with integrated networking, security, and administrative tools. It supports both traditional LoadBalancer and modern Cloudflare Tunnel connectivity patterns, with automatic SSL certificate management and admin application deployment.

## Features

- **Cost-Optimized AKS Cluster**: Ephemeral OS disks, burstable VMs, and auto-scaling
- **Dual Networking Modes**: Azure LoadBalancer or Cloudflare Tunnel connectivity
- **Automatic SSL Management**: cert-manager with Let's Encrypt integration
- **Admin Applications**: Optional Rancher and Grafana deployment
- **Integrated DNS**: Automatic DNS record creation for exposed services
- **Security by Design**: Managed identity, no hardcoded secrets, private networking
- **Production Ready**: Health probes, monitoring, and automated certificate renewal

## Architecture

The module creates a complete Kubernetes environment with:

### Core Infrastructure
- **Azure Resource Group**: Dedicated resource group for cluster resources
- **AKS Cluster**: Managed Kubernetes cluster with auto-scaling node pool
- **System Identity**: Managed identity for secure Azure resource access

### Networking Options
- **LoadBalancer Mode**: Traditional Azure LoadBalancer with public IP
- **Tunnel Mode**: Cloudflare Tunnel for secure connectivity without public IPs

### Administrative Components
- **NGINX Ingress Controller**: Traffic routing and SSL termination
- **cert-manager**: Automatic SSL certificate provisioning and renewal
- **Let's Encrypt Issuers**: Production and staging certificate authorities
- **Rancher** (optional): Kubernetes management interface
- **Grafana** (optional): Monitoring and observability dashboard

## Usage

### Cost-Optimized Production Cluster

```hcl
module "aks_cluster" {
  source = "../../../modules/azure/aks-cluster"
  
  # Azure Configuration
  azure_subscription_id = var.azure_subscription_id
  azure_region         = "westeurope"
  
  # Cluster Configuration
  cluster_name           = "aks-production"
  cluster_vm_size        = "Standard_B2s"    # Cost-optimized burstable VM
  cluster_vm_disk_size   = 30               # Ephemeral OS disk limit
  cluster_vm_min_node_count = 1
  cluster_vm_max_node_count = 3
  
  # SSL Configuration
  letsencrypt_email = "admin@example.com"
  
  # Networking - Cloudflare Tunnel (no public IPs)
  load_balancer_enabled = false
  tunnel_enabled        = true
  
  # Cloudflare Configuration
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_id    = var.cloudflare_zone_id
  
  # Admin Applications
  rancher_enabled = true
  rancher_dns     = "rancher.example.com"
}
```

### Traditional LoadBalancer Cluster

```hcl
module "aks_cluster" {
  source = "../../../modules/azure/aks-cluster"
  
  # Azure Configuration
  azure_subscription_id = var.azure_subscription_id
  azure_region         = "westeurope"
  
  # Cluster Configuration
  cluster_name           = "aks-production"
  cluster_vm_size        = "Standard_D4s_v3"  # Higher performance
  cluster_vm_min_node_count = 2
  cluster_vm_max_node_count = 10
  
  # SSL Configuration
  letsencrypt_email = "admin@example.com"
  
  # Networking - Azure LoadBalancer
  load_balancer_enabled = true
  tunnel_enabled        = false
  
  # Admin Applications
  rancher_enabled = true
  rancher_dns     = "rancher.example.com"
  grafana_enabled = true
}
```

### Development Environment

```hcl
module "aks_cluster" {
  source = "../../../modules/azure/aks-cluster"
  
  # Azure Configuration
  azure_subscription_id = var.azure_subscription_id
  azure_region         = "westeurope"
  
  # Cluster Configuration
  cluster_name           = "aks-dev"
  cluster_vm_size        = "Standard_D8s_v3"  # Fast development machine
  cluster_vm_disk_size   = 128               # Larger ephemeral disk
  cluster_vm_min_node_count = 1
  cluster_vm_max_node_count = 1
  
  # SSL Configuration
  letsencrypt_email = "admin@example.com"
  
  # Networking
  load_balancer_enabled = false
  tunnel_enabled        = true
  
  # Cloudflare Configuration
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
  
  # Disable admin apps for development
  rancher_enabled = false
  grafana_enabled = false
}
```

## Variables

### Azure Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `azure_subscription_id` | The subscription ID for the Azure account | `string` | n/a | yes |
| `azure_region` | The Azure region for the resources | `string` | `"westeurope"` | no |

### Cluster Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | The name of the AKS cluster | `string` | `"aks-westeu-prod"` | no |
| `cluster_vm_size` | The VM size for the AKS cluster | `string` | `"Standard_B2s"` | no |
| `cluster_vm_disk_size` | The VM disk size for the AKS cluster | `string` | `"30"` | no |
| `cluster_vm_min_node_count` | The minimum number of nodes in the default node pool | `number` | `1` | no |
| `cluster_vm_max_node_count` | The maximum number of nodes in the default node pool | `number` | `1` | no |
| `cluster_vm_max_pods_count` | The maximum number of pods in the default node pool | `number` | `30` | no |

### SSL Certificate Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `letsencrypt_email` | The email address for Let's Encrypt notifications | `string` | n/a | yes |

### Networking Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `load_balancer_enabled` | Enable Azure Load Balancer for outbound connectivity | `bool` | `true` | no |
| `tunnel_enabled` | Whether to enable Cloudflare tunnel mode | `bool` | `false` | no |

### Cloudflare Configuration
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cloudflare_api_token` | The api token for Cloudflare | `string` | `null` | no |
| `cloudflare_account_id` | The account id for Cloudflare | `string` | `null` | no |
| `cloudflare_zone_id` | The zone id to update | `string` | `null` | no |

### Admin Applications
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `rancher_enabled` | Whether to enable the Rancher server | `bool` | `false` | no |
| `rancher_dns` | The DNS name for the Rancher server | `string` | `null` | no |
| `grafana_enabled` | Whether to enable the Grafana server | `bool` | `false` | no |

## Outputs

### Azure Configuration
| Name | Description | Sensitive |
|------|-------------|-----------|
| `azure_region` | The Azure region where the cluster is deployed | No |
| `azure_resource_group_name` | The resource group name of the AKS cluster | No |
| `azure_load_balancer_enabled` | Whether Azure Load Balancer is enabled | No |
| `azure_load_balancer_external_ip` | The external IP address of the Load Balancer | No |

### Cluster Configuration
| Name | Description | Sensitive |
|------|-------------|-----------|
| `cluster_name` | The name of the AKS cluster | No |
| `kube_config` | The raw kubeconfig for the AKS cluster | Yes |

### Cloudflare Tunnel Configuration
| Name | Description | Sensitive |
|------|-------------|-----------|
| `cloudflare_tunnel_enabled` | Whether Cloudflare tunnel is enabled | No |
| `cloudflare_tunnel_cname` | The CNAME for the Cloudflare tunnel | No |

## Networking Modes

### LoadBalancer Mode (`load_balancer_enabled = true`)
- **Public IP**: Azure LoadBalancer with external IP address
- **Cost**: Higher cost due to LoadBalancer and public IP resources
- **Use Case**: Traditional Kubernetes setup, direct external access
- **DNS**: A records pointing to LoadBalancer IP

### Tunnel Mode (`tunnel_enabled = true`)
- **No Public IP**: All traffic routed through Cloudflare Tunnel
- **Cost**: Lower cost, no LoadBalancer or public IP charges
- **Use Case**: Secure connectivity, DDoS protection, global CDN
- **DNS**: CNAME records pointing to tunnel endpoint

## Cost Optimization Features

### Ephemeral OS Disks
- **Benefits**: Faster I/O, lower cost, automatic cleanup
- **Limitation**: 30GB maximum size for Standard_B2s VMs
- **Use Case**: Stateless workloads with persistent storage on separate volumes

### Burstable VMs (Standard_B2s)
- **CPU**: 2 vCPUs with burst capability
- **Memory**: 4GB RAM
- **Cost**: Significant savings compared to dedicated compute
- **Use Case**: Variable workloads, development, small production

### Auto-Scaling
- **Dynamic Scaling**: Automatically adjusts node count based on demand
- **Cost Control**: Only pay for nodes when needed
- **Configuration**: Customizable min/max node counts

## Admin Applications

### Rancher
- **Purpose**: Kubernetes cluster management and monitoring
- **Access**: Web interface via configured DNS name
- **Features**: Cluster monitoring, application deployment, user management

### Grafana
- **Purpose**: Metrics visualization and monitoring dashboards
- **Integration**: Pre-configured with cluster monitoring
- **Features**: Custom dashboards, alerting, data visualization

## Monitoring and Observability

### Health Probes
- **Readiness**: Ensures pods are ready to receive traffic
- **Liveness**: Automatically restarts unhealthy pods
- **Azure Integration**: LoadBalancer health checks

### Cluster Monitoring
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Monitor resource usage
kubectl top nodes
kubectl top pods -A

# View cluster events
kubectl get events -A --sort-by='.lastTimestamp'
```

### Admin Access
```bash
# Access Rancher (if enabled)
open https://rancher.example.com

# Access Grafana (if enabled)
kubectl port-forward -n grafana svc/grafana 3000:80
open http://localhost:3000
```

## Dependencies

- **Azure CLI**: Authentication and resource management
- **kubectl**: Kubernetes cluster interaction
- **Helm**: Package management (handled by Terraform)
- **Cloudflare Account**: For tunnel mode (optional)
- **Domain Management**: DNS zone in Cloudflare (for tunnel mode)

## Related Modules

- `helm/cert-manager`: SSL certificate management
- `helm/ingress-nginx`: Traffic routing and load balancing
- `helm/letsencrypt-cert-issuer`: Let's Encrypt certificate issuers
- `helm/rancher`: Kubernetes management interface
- `helm/grafana`: Monitoring and observability
- `cloudflare/tunnel`: Tunnel infrastructure creation
- `helm/cloudflared`: Tunnel client deployment
- `cloudflare/dns-record`: DNS record management
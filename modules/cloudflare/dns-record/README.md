# Cloudflare DNS Record Module

This Terraform module creates a Cloudflare DNS record that can handle both load balancer IP addresses (A records) and tunnel CNAMEs (CNAME records) based on cluster configuration.

## Features

- **Automatic Record Type**: Creates A records for load balancers, CNAME records for tunnels
- **Conditional Creation**: Only creates records when load balancer or tunnel is enabled
- **Configurable Options**: TTL, proxying, and enable/disable settings
- **Comprehensive Outputs**: Returns record details for downstream usage

## Usage

### Load Balancer DNS Record (A Record)
```hcl
module "app_dns" {
  source = "../../cloudflare/dns-record"
  
  zone_id               = var.cloudflare_zone_id
  name                  = "app"
  load_balancer_enabled = true
  tunnel_enabled        = false
  record_content        = "203.0.113.1"
  ttl                   = 300
  proxied               = false
}
```

### Tunnel DNS Record (CNAME Record)
```hcl
module "app_dns" {
  source = "../../cloudflare/dns-record"
  
  zone_id               = var.cloudflare_zone_id
  name                  = "app"
  load_balancer_enabled = false
  tunnel_enabled        = true
  record_content        = "abcd1234.cfargotunnel.com"
  ttl                   = 1
  proxied               = true
}
```

### Conditional Creation with Cluster State
```hcl
module "app_dns" {
  source = "../../cloudflare/dns-record"
  
  enabled               = true
  zone_id               = var.cloudflare_zone_id
  name                  = var.app_subdomain
  load_balancer_enabled = data.terraform_remote_state.cluster.outputs.azure_load_balancer_enabled
  tunnel_enabled        = data.terraform_remote_state.cluster.outputs.cloudflare_tunnel_enabled
  record_content        = data.terraform_remote_state.cluster.outputs.azure_load_balancer_enabled ? 
                         data.terraform_remote_state.cluster.outputs.azure_load_balancer_external_ip :
                         data.terraform_remote_state.cluster.outputs.cloudflare_tunnel_cname
  ttl                   = 1
  proxied               = true
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| zone_id | Cloudflare zone ID | `string` | n/a | yes |
| name | DNS record name | `string` | n/a | yes |
| load_balancer_enabled | Whether the load balancer is enabled | `bool` | n/a | yes |
| tunnel_enabled | Whether the tunnel is enabled | `bool` | n/a | yes |
| record_content | The content of the DNS record (IP for A record, CNAME for CNAME record) | `string` | `null` | no |
| ttl | TTL for the DNS record | `number` | `1` | no |
| proxied | Whether the record should be proxied through Cloudflare | `bool` | `false` | no |
| enabled | Whether to create the DNS record | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| record_id | The ID of the created DNS record |
| record_name | The name of the created DNS record |
| record_content | The content of the created DNS record |
| record_type | The type of the created DNS record (A or CNAME) |
| fqdn | The fully qualified domain name of the record |

## Logic

The module creates DNS records based on the following logic:
- **Record Creation**: Only creates a record if `enabled = true` AND (`load_balancer_enabled = true` OR `tunnel_enabled = true`)
- **Record Type**: 
  - Creates an **A record** when `load_balancer_enabled = true`
  - Creates a **CNAME record** when `load_balancer_enabled = false` (and `tunnel_enabled = true`)

## Common Patterns

### Integration with AKS Cluster State
```hcl
data "terraform_remote_state" "aks_cluster" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-provisioning"
    storage_account_name = "stprovisioning"
    container_name       = "tfstate"
    key                  = "my-cluster.tfstate"
  }
}

module "app_dns" {
  source = "../../cloudflare/dns-record"
  
  zone_id               = var.cloudflare_zone_id
  name                  = "myapp"
  load_balancer_enabled = data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_enabled
  tunnel_enabled        = data.terraform_remote_state.aks_cluster.outputs.cloudflare_tunnel_enabled
  record_content        = try(data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_external_ip, 
                             data.terraform_remote_state.aks_cluster.outputs.cloudflare_tunnel_cname)
  ttl                   = 1
  proxied               = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| cloudflare | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| cloudflare | >= 4.0 |
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-provisioning-vse"
    storage_account_name = "stprovisioningvse"
    container_name       = "tfstate"
    key                  = "aks-vse-westeu-prod-v2.tfstate"
  }
}

module "aks_cluster" {
  source = "../../../solutions/aks-cluster"

  # Azure Configuration
  azure_subscription_id = var.azure_subscription_id
  azure_region          = "westeurope"

  # SSL Certificate Configuration
  letsencrypt_email = var.letsencrypt_email

  # Cluster Configuration
  cluster_name              = "aks-vse-westeu-prod-v2"
  cluster_vm_size           = "Standard_B2s" # Low memory (4GB) Burst VM (2CPU)
  cluster_vm_disk_size      = 30             # Max size of it's Ephemeral disk
  cluster_vm_min_node_count = 2
  cluster_vm_max_node_count = 2
  cluster_vm_max_pods_count = 40
  # cluster_worker_node_count = 1

  # Networking Configuration
  load_balancer_enabled = true
  tunnel_enabled        = false

  # Admin Applications
  rancher_enabled = false
  rancher_dns     = null
  grafana_enabled = false

  # Cloudflare DNS Configuration (in case the rancher_dns is set)
  cloudflare_zone_id = var.cloudflare_zone_id

  # Cloudflare Account configuration (in case of a tunnel)
  cloudflare_api_token  = var.cloudflare_api_token
  cloudflare_account_id = var.cloudflare_account_id
}

# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "azure_subscription_id" {
  description = "The subscription ID for the Azure account."
  type        = string
}
variable "cloudflare_api_token" {
  description = "The api token for Cloudflare. If not provided we don't update the dns."
  type        = string
  default     = null
}
variable "cloudflare_account_id" {
  description = "The account ID for Cloudflare."
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "The zone ID for Cloudflare DNS."
  type        = string
  default     = null
}

variable "letsencrypt_email" {
  description = "The email address used for Let's Encrypt registration."
  type        = string
}

# =============================================================================
# OUTPUTS
# =============================================================================

# Azure Configuration
output "azure_region" {
  description = "The Azure region where the cluster is deployed"
  value       = module.aks_cluster.azure_region
}

output "azure_resource_group_name" {
  description = "The resource group name of the AKS cluster"
  value       = module.aks_cluster.azure_resource_group_name
}

output "azure_load_balancer_enabled" {
  description = "Whether Azure Load Balancer is enabled"
  value       = module.aks_cluster.azure_load_balancer_enabled
}

output "azure_load_balancer_external_ip" {
  description = "The external IP address of the Load Balancer"
  value       = module.aks_cluster.azure_load_balancer_external_ip
}


# Cloudflare Tunnel Configuration
output "cloudflare_tunnel_enabled" {
  description = "Whether Cloudflare tunnel is enabled"
  value       = module.aks_cluster.cloudflare_tunnel_enabled
}

output "cloudflare_tunnel_cname" {
  description = "The CNAME for the Cloudflare tunnel"
  value       = module.aks_cluster.cloudflare_tunnel_cname
}

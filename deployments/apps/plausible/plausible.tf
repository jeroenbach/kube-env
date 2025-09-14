terraform {
  backend "azurerm" {
    resource_group_name  = "rg-provisioning-mpn"
    storage_account_name = "stprovisioningmpn"
    container_name       = "tfstate"
    key                  = "plausible-v2.1.1.tfstate"
  }
}
data "terraform_remote_state" "aks_cluster" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-provisioning-mpn"
    storage_account_name = "stprovisioningmpn"
    container_name       = "tfstate"
    key                  = "aks-mpn-westeu-prod.tfstate"
  }
}

module "plausible" {
  source = "../../../solutions/plausible"

  # Azure Configuration (from remote state)
  azure_subscription_id          = var.azure_subscription_id
  azure_disk_resource_group_name = "rg-nodes-aks-mpn-westeu-prod"
  azure_disk_location            = data.terraform_remote_state.aks_cluster.outputs.azure_region

  # AKS Configuration
  namespace = "plausible-analytics-v2"
  name      = "plausible-analytics-v2"
  chart_version   = "0.3.3"

  # Plausible Configuration
  plausible_dns = "plausible.bach.software"

  # Cloudflare Configuration (in case dns is to be updated)
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id   = var.cloudflare_zone_id

  # Cluster Configuration (from remote state)
  load_balancer_enabled = data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_enabled
  tunnel_enabled        = data.terraform_remote_state.aks_cluster.outputs.cloudflare_tunnel_enabled
  record_content        = data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_enabled ? try(data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_external_ip, null) : try(data.terraform_remote_state.aks_cluster.outputs.cloudflare_tunnel_cname, null)

  # Database Restore Configuration (optional)
  postgresql_restore_snapshot_id = "/subscriptions/3243bcdf-6e19-43a5-9b59-ab769838ff01/resourceGroups/Shared/providers/Microsoft.Compute/snapshots/plausible-postgresql"
  clickhouse_restore_snapshot_id = "/subscriptions/3243bcdf-6e19-43a5-9b59-ab769838ff01/resourceGroups/Shared/providers/Microsoft.Compute/snapshots/plausible-clickhousev3"
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
variable "cloudflare_zone_id" {
  description = "The zone ID for Cloudflare DNS. If not provided we don't update the dns."
  type        = string
  default     = null
}

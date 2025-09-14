terraform {
  backend "azurerm" {
    resource_group_name  = "rg-provisioning-mpn"
    storage_account_name = "stprovisioningmpn"
    container_name       = "tfstate"
    key                  = "plausible-v3.0.1.tfstate"
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

# =============================================================================
# PLAUSIBLE ANALYTICS v3 DEPLOYMENT is using 50% more cpu resources then v2
# due to the new ClickHouse database with new features. These features are not used in Plausible.
# Therefore is better to stay at v2 for now.
# 
# Plausible v3 is not actively using most of the new ClickHouse 24.12 features that would justify the increased CPU usage. Here's what I found:
# 
#   Plausible v3 ClickHouse Usage:
# 
#   New Schema Elements:
#   - Added acquisition_channel_paid_sources and acquisition_channel_source_category tables (simple lookup tables)
#   - These are basic dictionary tables, not leveraging advanced ClickHouse 24.12 features
# 
#   Limited Feature Utilization:
#   - Plausible's changelog shows minimal ClickHouse-specific changes in v3
#   - Main changes are administrative (debug routes, buffer size settings)
#   - No evidence of using new compression, execution engines, or optimization features
# 
#   The Real Issue:
# 
#   The 53% CPU increase (230m → 352m) appears to be overhead from ClickHouse 24.12 itself, not from Plausible utilizing new features. ClickHouse 24.12 has:
# 
#   1. More aggressive background optimization running by default
#   2. Enhanced query planning that uses more CPU upfront
#   3. Improved concurrent processing with higher resource usage
#   4. New default settings optimized for performance over efficiency
# 
#   Recommendation:
# 
#   Since Plausible isn't leveraging the new ClickHouse capabilities, you could potentially:
# 
#   1. Tune ClickHouse 24.12 to be less aggressive (reduce background merge frequency, disable some optimizations)
#   2. Set CPU limits in your Kubernetes deployment if resources are constrained
#   3. Consider staying on v2 if the performance gains don't justify the 53% CPU increase
# 
#   The CPU increase is essentially "paying" for ClickHouse improvements that Plausible isn't fully utilizing yet.
# =============================================================================
module "plausible" {
  source = "../../../solutions/plausible"

  # Azure Configuration (from remote state)
  azure_subscription_id          = var.azure_subscription_id
  azure_disk_resource_group_name = "rg-nodes-aks-mpn-westeu-prod"
  azure_disk_location            = data.terraform_remote_state.aks_cluster.outputs.azure_region

  # AKS Configuration
  namespace = "plausible-analytics-v3"
  name      = "plausible-analytics-v3"
  chart_version   = "0.4.2"

  # Plausible Configuration
  plausible_dns = "plausiblev3.bach.software"

  # Cloudflare Configuration (in case dns is to be updated)
  cloudflare_api_token = var.cloudflare_api_token
  cloudflare_zone_id   = var.cloudflare_zone_id

  # Cluster Configuration (from remote state)
  load_balancer_enabled = data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_enabled
  tunnel_enabled        = data.terraform_remote_state.aks_cluster.outputs.cloudflare_tunnel_enabled
  record_content        = data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_enabled ? try(data.terraform_remote_state.aks_cluster.outputs.azure_load_balancer_external_ip, null) : try(data.terraform_remote_state.aks_cluster.outputs.cloudflare_tunnel_cname, null)

  # Database Restore Configuration (optional)
  postgresql_restore_snapshot_id = "/subscriptions/3243bcdf-6e19-43a5-9b59-ab769838ff01/resourceGroups/Shared/providers/Microsoft.Compute/snapshots/plausible-postgresql-upgraded"
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

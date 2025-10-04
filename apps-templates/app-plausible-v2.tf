/**
Doesn't work anymore due to dependency on bitnami deleted 
container images. 
*/
module "plausible" {
  source = "../modules/app-plausible"

  # Azure Configuration
  azure_disk_resource_group_name = module.aks_cluster.azure_nodes_resource_group_name
  azure_disk_location            = "westeurope"

  # AKS Configuration
  namespace = "plausible-analytics-v2"
  name      = "plausible-analytics-v2"
  chart_version   = "0.3.3"

  # Plausible Configuration
  plausible_dns = var.plausible_dns

  # Database Restore Configuration (optional)
  postgresql_restore_snapshot_id = var.postgresql_restore_snapshot_id
  clickhouse_restore_snapshot_id = var.clickhouse_restore_snapshot_id

  depends_on = [ module.aks_cluster ]
}

resource "cloudflare_dns_record" "record" {
  count   = var.cloudflare_api_token != null && var.cloudflare_api_token != "" && var.cloudflare_zone_id != null  && var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.plausible_dns
  content = module.aks_cluster.azure_load_balancer_external_ip
  type    = "A"
  ttl     = 1
  proxied = false

  depends_on = [ module.aks_cluster ]
}

# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "cloudflare_api_token" {
  description = "The api token for Cloudflare. If not provided we don't update the dns."
  type        = string
}
variable "cloudflare_zone_id" {
  description = "The zone ID for Cloudflare DNS. If not provided we don't update the dns."
  type        = string
}
variable "plausible_dns" {
  description = "The DNS name for the Plausible server. Even when not using cloudflare, this is used in the plausible configuration."
  type        = string
}
variable "postgresql_restore_snapshot_id" {
  description = "The Azure snapshot ID to restore PostgreSQL data from. Format: /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/snapshots/<snapshot-name>. Leave empty to start with a fresh database."
  type        = string
}
variable "clickhouse_restore_snapshot_id" {
  description = "The Azure snapshot ID to restore ClickHouse data from. Format: /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/snapshots/<snapshot-name>. Leave empty to start with a fresh database."
  type        = string
}
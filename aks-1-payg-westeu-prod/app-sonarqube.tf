module "sonarqube" {
  source = "../modules/app-sonarqube"

  # Azure Configuration
  azure_disk_resource_group_name = module.aks_cluster.azure_nodes_resource_group_name
  azure_disk_location            = "westeurope"

  # SonarQube Configuration
  sonarqube_dns           = var.sonarqube_dns
  sonarqube_replica_count = var.sonarqube_replica_count

  # Database Restore Configuration (optional)
  sonarqube_restore_snapshot_id  = var.sonarqube_data_restore_snapshot_id
  postgresql_restore_snapshot_id = var.sonarqube_postgresql_restore_snapshot_id

  depends_on = [module.aks_cluster]
}

resource "cloudflare_dns_record" "sonarqube" {
  count   = var.cloudflare_api_token != null && var.cloudflare_api_token != "" && var.cloudflare_zone_id != null && var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.sonarqube_dns
  content = module.aks_cluster.azure_load_balancer_external_ip
  type    = "A"
  ttl     = 1
  proxied = false

  depends_on = [module.aks_cluster]
}

# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "sonarqube_dns" {
  description = "The DNS name for the SonarQube server. Even when not using Cloudflare, this is used in the ingress/TLS configuration."
  type        = string
}
variable "sonarqube_replica_count" {
  description = "Set to 1 to turn SonarQube on (e.g. while running PR pipelines), or 0 to turn it off and save cost. Toggle this and re-run `pnpm run aks-1:apply`."
  type        = number
  default     = 0
}
variable "sonarqube_data_restore_snapshot_id" {
  description = "The Azure snapshot ID to restore SonarQube's data disk from. Format: /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/snapshots/<snapshot-name>. Leave empty to start with a fresh instance."
  type        = string
  default     = null
}
variable "sonarqube_postgresql_restore_snapshot_id" {
  description = "The Azure snapshot ID to restore SonarQube's PostgreSQL data from. Format: /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Compute/snapshots/<snapshot-name>. Leave empty to start with a fresh database."
  type        = string
  default     = null
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "sonarqube_url" {
  description = "The URL SonarQube is reachable on."
  value       = module.sonarqube.sonarqube_url
}

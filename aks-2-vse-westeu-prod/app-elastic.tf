module "elastic_stack" {
  source = "../modules/app-elastic-stack"

  # Azure Configuration
  azure_disk_resource_group_name = module.aks_cluster.azure_nodes_resource_group_name
  azure_disk_location            = "westeurope"

  # Elasticsearch Configuration
  kibana_dns                        = var.kibana_dns
  elasticsearch_restore_snapshot_id = var.elasticsearch_restore_snapshot_id
  
  depends_on = [ module.aks_cluster ]
}

# Cloudflare DNS record for Kibana
resource "cloudflare_dns_record" "kibana" {
  count   = var.kibana_dns != null && var.kibana_dns != "" && var.cloudflare_api_token != null && var.cloudflare_api_token != "" && var.cloudflare_zone_id != null && var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.kibana_dns
  content = module.aks_cluster.azure_load_balancer_external_ip
  type    = "A"
  ttl     = 1
  proxied = false

  depends_on = [ module.aks_cluster ]
}

# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "kibana_dns" {
  description = "The DNS name for Kibana."
  type        = string
}

# variable "letsencrypt_email" {
#   description = "The email address for Let's Encrypt notifications"
#   type        = string
# }

# variable "cloudflare_api_token" {
#   description = "Cloudflare API token for DNS management"
#   type        = string
#   default     = null
#   sensitive   = true
# }

# variable "cloudflare_zone_id" {
#   description = "Cloudflare zone ID for DNS management"
#   type        = string
#   default     = null
# }

variable "elasticsearch_restore_snapshot_id" {
  description = "The resource id of the snapshot to restore. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "elasticsearch_username" {
  description = "Elasticsearch username (always 'elastic')"
  value       = module.elastic_stack.elasticsearch_username
}

output "elasticsearch_password" {
  description = "Elasticsearch password"
  value       = module.elastic_stack.elasticsearch_password
  sensitive   = true
}

output "kibana_url" {
  description = "Kibana URL"
  value       = module.elastic_stack.kibana_url
}

output "elasticsearch_password_command" {
  description = "Command to retrieve the Elasticsearch password"
  value       = "terraform output -raw elasticsearch_password"
}

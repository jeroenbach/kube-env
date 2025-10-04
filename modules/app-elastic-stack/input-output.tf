# =============================================================================
# AZURE CONFIGURATION
# =============================================================================
variable "azure_disk_resource_group_name" {
  description = "The resource group for the disk."
  type        = string
}
variable "azure_disk_location" {
  description = "The location to restore the snapshot to."
  type        = string
}


# =============================================================================
# ELASTICSEARCH CONFIGURATION
# =============================================================================
variable "kibana_dns" {
  description = "The DNS name for the Elasticsearch server."
  type        = string
}

variable "elasticsearch_data_disk_size" {
  description = "The size of the data disk for the Elasticsearch server."
  type        = number
  default     = 10
}

# =============================================================================
# DATABASE RESTORE CONFIGURATION
# =============================================================================
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
  value       = "elastic"
}

output "elasticsearch_password" {
  description = "Elasticsearch password"
  value       = data.external.elasticsearch_password.result.password
  sensitive   = true
}

output "kibana_url" {
  description = "Kibana URL"
  value       = var.kibana_dns != null && var.kibana_dns != "" ? "https://${var.kibana_dns}" : "kubectl port-forward svc/kibana-kb-http -n elastic-stack 5601:5601"
}

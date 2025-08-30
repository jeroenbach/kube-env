# =============================================================================
# AZURE CONFIGURATION
# =============================================================================
variable "azure_subscription_id" {
  description = "The subscription ID for the Azure account."
  type        = string
}

variable "azure_disk_resource_group_name" {
  description = "The resource group for the disk."
  type        = string
}

variable "azure_disk_location" {
  description = "The location to restore the snapshot to."
  type        = string
}

# =============================================================================
# HELM DEPLOYMENT CONFIGURATION
# =============================================================================
variable "namespace" {
  description = "The namespace to deploy Plausible into."
  type        = string
  default     = "plausible-analytics"
}

variable "name" {
  description = "The name to use for the Helm release."
  type        = string
  default     = "plausible-analytics"
}

variable "chart_version" {
  description = "The version of the Helm chart."
  type        = string
  default     = "0.3.3"
}

# =============================================================================
# CLOUDFLARE CONFIGURATION
# =============================================================================
variable "cloudflare_api_token" {
  description = "The API token for Cloudflare. If not specified we don't update the DNS."
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "The zone ID for Cloudflare DNS. If not specified we don't update the DNS."
  type        = string
  default     = null
}

variable "load_balancer_enabled" {
  description = "Whether to enable the load balancer."
  type        = bool
  default     = false
}
variable "tunnel_enabled" {
  description = "Whether to enable the tunnel."
  type        = bool
  default     = false
}

variable "record_content" {
  description = "The content of the DNS record."
  type        = string
  default     = null
}


# =============================================================================
# PLAUSIBLE CONFIGURATION
# =============================================================================
variable "plausible_dns" {
  description = "The DNS name for the Plausible server."
  type        = string
}

variable "plausible_data_disk_size" {
  description = "The size of the data disk for the Plausible server."
  type        = number
  default     = 8
}
variable "plausible_config_disk_size" {
  description = "The size of the posgres config disk for the Plausible server."
  type        = number
  default     = 1
}

# =============================================================================
# DATABASE RESTORE CONFIGURATION
# =============================================================================
variable "postgresql_restore_snapshot_id" {
  description = "The resource id of the snapshot to restore. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

variable "clickhouse_restore_snapshot_id" {
  description = "The resource id of the snapshot to restore. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

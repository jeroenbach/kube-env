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
# HELM DEPLOYMENT CONFIGURATION
# =============================================================================
variable "namespace" {
  description = "The namespace to deploy SonarQube into."
  type        = string
  default     = "sonarqube"
}

variable "name" {
  description = "The name to use for the Helm release."
  type        = string
  default     = "sonarqube"
}

variable "chart_version" {
  description = "The version of the Helm chart."
  type        = string
  default     = "2026.3.1"
}

# =============================================================================
# SONARQUBE CONFIGURATION
# =============================================================================
variable "sonarqube_dns" {
  description = "The DNS name for the SonarQube server."
  type        = string
}

variable "sonarqube_replica_count" {
  description = "Set to 1 to turn SonarQube on, or 0 to turn it off. Data is preserved either way - this only controls whether the pod (and the extra autoscaled node it needs) is running. Defaults to off, since it's expensive to keep running all the time."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1], var.sonarqube_replica_count)
    error_message = "sonarqube_replica_count must be 0 (off) or 1 (on). SonarQube doesn't support running more than one instance against the same database."
  }
}

variable "sonarqube_data_disk_size" {
  description = "The size of the data disk for SonarQube (data, extensions and logs)."
  type        = number
  default     = 10
}

variable "postgresql_data_disk_size" {
  description = "The size of the data disk for SonarQube's PostgreSQL database."
  type        = number
  default     = 5
}

# =============================================================================
# DATABASE RESTORE CONFIGURATION
# =============================================================================
variable "sonarqube_restore_snapshot_id" {
  description = "The resource id of the snapshot to restore SonarQube's data disk from. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

variable "postgresql_restore_snapshot_id" {
  description = "The resource id of the snapshot to restore PostgreSQL's data disk from. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

# =============================================================================
# OUTPUTS
# =============================================================================
output "sonarqube_url" {
  description = "The URL SonarQube is reachable on."
  value       = "https://${var.sonarqube_dns}"
}

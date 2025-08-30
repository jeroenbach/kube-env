# =============================================================================
# AZURE CONFIGURATION
# =============================================================================

variable "azure_subscription_id" {
  description = "The subscription ID for the Azure account."
  type        = string
}

variable "azure_region" {
  description = "The Azure region for the resources."
  type        = string
  default     = "westeurope"
}

# =============================================================================
# CLOUDFLARE CONFIGURATION
# =============================================================================
variable "cloudflare_api_token" {
  description = "The api token for Cloudflare. If not provided we don't update the dns."
  type        = string
  default     = null
}

variable "cloudflare_account_id" {
  description = "The account id for Cloudflare."
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "The zone id to update"
  type        = string
  default     = null
}

# =============================================================================
# CLUSTER CONFIGURATION
# =============================================================================
variable "cluster_name" {
  description = "The name of the AKS cluster."
  type        = string
  default     = "aks-westeu-prod"
}

variable "cluster_vm_size" {
  description = "The VM size for the AKS cluster."
  type        = string
  default     = "Standard_B2s" # Low memory (4GB) Burst VM (2CPU)
}

variable "cluster_vm_disk_size" {
  description = "The VM disk size for the AKS cluster."
  type        = string
  default     = "30" # Max size of it's Ephemeral disk
}

variable "cluster_vm_min_node_count" {
  description = "The minimum number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "cluster_vm_max_node_count" {
  description = "The maximum number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "cluster_vm_max_pods_count" {
  description = "The maximum number of pods in the default node pool."
  type        = number
  default     = 30
}

variable "cluster_worker_node_count" {
  description = "The number of worker nodes in the cluster."
  type        = number
  default     = 0
}

# =============================================================================
# SSL CERTIFICATE CONFIGURATION
# =============================================================================
variable "letsencrypt_email" {
  description = "The email address for Let's Encrypt notifications"
  type        = string
}

# =============================================================================
# NETWORKING CONFIGURATION
# =============================================================================
variable "load_balancer_enabled" {
  description = "Enable Azure Load Balancer for outbound connectivity. When false, uses Cloudflare tunnel mode. Default: true for backward compatibility."
  type        = bool
  default     = true
}

variable "tunnel_enabled" {
  description = "Whether to enable Cloudflare tunnel mode"
  type        = bool
  default     = false
}

# =============================================================================
# ADMIN APPLICATIONS
# =============================================================================
variable "rancher_enabled" {
  description = "Whether to enable the Rancher server"
  type        = bool
  default     = false
}

variable "rancher_dns" {
  description = "The DNS name for the Rancher server. If left empty, Rancher will not be exposed externally."
  type        = string
  default     = null
}

variable "grafana_enabled" {
  description = "Whether to enable the Grafana server"
  type        = bool
  default     = false
}

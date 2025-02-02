variable "subscription_id" {
  description = "The subscription ID for the Azure account."
  type        = string
}

variable "min_node_count" {
  description = "The minimum number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "The maximum number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "max_pods_count" {
  description = "The maximum number of pods on a node"
  type        = number
  default     = 40
}

variable "letsencrypt_email" {
  description = "The email address for Let's Encrypt notifications"
  type        = string
}

variable "cloudflare_api_token" {
  description = "The api token for Cloudflare. If not provided we don't update the dns."
  type        = string
  default     = null
}

variable "cloudflare_zone_id" {
  description = "The zone id to update"
  type        = string
  default     = null
}

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

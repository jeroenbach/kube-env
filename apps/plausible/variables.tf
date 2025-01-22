variable "subscription_id" {
  description = "The subscription ID for the Azure account."
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

variable "root_domain" {
  description = "The domain name for the root website."
  type        = string
}

variable "plausible_dns" {
  description = "The DNS name for the Plausible server."
  type        = string
}

variable "resource_group_name" {
  description = "The resource group to restore the snapshot to."
  type        = string
  default     = null
}

variable "location" {
  description = "The location to restore the snapshot to."
  type        = string
  default     = null
}

variable "postgresql_source_resource_id" {
  description = "The resource id of the snapshot to restore. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

variable "clickhouse_source_resource_id" {
  description = "The resource id of the snapshot to restore. If not specified we create a new disk from scratch."
  type        = string
  default     = null
}

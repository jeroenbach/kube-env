variable "zone_id" {
  description = "Cloudflare zone ID"
  type        = string
}

variable "name" {
  description = "DNS record name"
  type        = string
}

variable "load_balancer_enabled" {
  description = "Whether the load balancer is enabled"
  type        = bool
}

variable "tunnel_enabled" {
  description = "Whether the tunnel is enabled"
  type        = bool
}

variable "record_content" {
  description = "The content of the DNS record."
  type        = string
  default     = null
}

variable "ttl" {
  description = "TTL for the DNS record"
  type        = number
  default     = 1
}

variable "proxied" {
  description = "Whether the record should be proxied through Cloudflare"
  type        = bool
  default     = true
}

variable "enabled" {
  description = "Whether to create the DNS record"
  type        = bool
  default     = true
}
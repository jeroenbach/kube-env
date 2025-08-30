variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "tunnel_name" {
  description = "Name of the Cloudflare tunnel"
  type        = string
}

variable "ingress_service" {
  description = "Kubernetes service URL for ingress routing"
  type        = string
}

# =============================================================================
# CLOUDFLARE CONFIGURATION
# =============================================================================

variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "tunnel_id" {
  description = "Cloudflare tunnel ID"
  type        = string
}

variable "tunnel_name" {
  description = "Cloudflare tunnel name"
  type        = string
}

variable "tunnel_credentials" {
  description = "Base64-encoded tunnel credentials (sensitive)"
  type        = string
  sensitive   = true
}

# =============================================================================
# INGRESS CONFIGURATION
# =============================================================================

variable "ingress_service" {
  description = "Target service name for ingress routing"
  type        = string
  default     = "ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
}

# =============================================================================
# DEPLOYMENT CONFIGURATION
# =============================================================================

variable "replica_count" {
  description = "Number of pod replicas for high availability"
  type        = number
  default     = 1

  validation {
    condition     = var.replica_count >= 1 && var.replica_count <= 10
    error_message = "Replica count must be between 1 and 10."
  }
}

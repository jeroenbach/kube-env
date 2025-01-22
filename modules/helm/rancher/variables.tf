variable "rancher_dns" {
  description = "The DNS name for the Rancher server. If left empty we don't expose Rancher externally."
  type        = string
  default     = null
}

variable "letsencrypt_email" {
  description = "The email address for Let's Encrypt notifications"
  type        = string
}

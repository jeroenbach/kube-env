variable "service_type" {
  description = "The service type for the ingress-nginx controller (LoadBalancer, ClusterIP, or NodePort)"
  type        = string
  default     = "LoadBalancer"
  
  validation {
    condition = contains(["LoadBalancer", "ClusterIP", "NodePort"], var.service_type)
    error_message = "Service type must be one of: LoadBalancer, ClusterIP, or NodePort."
  }
}
# =============================================================================
# INPUT
# =============================================================================
variable "azure_region" {
  description = "The Azure region for the resources."
  type        = string
  default     = "westeurope"
}
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
  default     = 40
}
variable "cluster_worker_node_count" {
  description = "The number of worker nodes in the AKS cluster."
  type        = number
  default     = 0
}
variable "letsencrypt_email" {
  description = "The email address for Let's Encrypt notifications"
  type        = string
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "azure_load_balancer_external_ip" {
  description = "The external IP address of the Load Balancer (null when LoadBalancer is disabled)"
  value       = data.external.ingress_external_ip.result.ip
}

output "azure_nodes_resource_group_name" {
  description = "The resource group name for the AKS nodes"
  value       = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

output "kube_config" {
  description = "The structured kubeconfig for the AKS cluster"
  value = {
    host                   = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.host
    client_certificate     = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_certificate
    client_key             = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.aks_cluster.kube_config.0.cluster_ca_certificate
  }
  sensitive = true
}

output "kube_config_raw" {
  description = "The raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive   = true
}

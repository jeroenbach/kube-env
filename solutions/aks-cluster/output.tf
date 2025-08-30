# =============================================================================
# AZURE CONFIGURATION
# =============================================================================
output "azure_region" {
  description = "The Azure region where the cluster is deployed"
  value       = azurerm_kubernetes_cluster.aks_cluster.location
}

output "azure_resource_group_name" {
  description = "The resource group name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.resource_group_name
}

output "azure_load_balancer_enabled" {
  description = "Whether Azure Load Balancer is enabled"
  value       = var.load_balancer_enabled
}

output "azure_load_balancer_external_ip" {
  description = "The external IP address of the Load Balancer (null when LoadBalancer is disabled)"
  value       = var.load_balancer_enabled ? module.ingress_nginx.external_ip : null
}

# =============================================================================
# CLOUDFLARE TUNNEL CONFIGURATION
# =============================================================================
output "cloudflare_tunnel_enabled" {
  description = "Whether Cloudflare tunnel is enabled"
  value       = var.tunnel_enabled
}

output "cloudflare_tunnel_cname" {
  description = "The CNAME for the Cloudflare tunnel (null when tunnel is disabled)"
  value       = var.tunnel_enabled && length(module.cloudflare_tunnel) > 0 ? module.cloudflare_tunnel[0].tunnel_cname : null
}

# =============================================================================
# CLUSTER CONFIGURATION
# =============================================================================
output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}

output "kube_config" {
  description = "The raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive   = true
}

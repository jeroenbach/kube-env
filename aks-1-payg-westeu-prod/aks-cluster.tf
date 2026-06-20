module "aks_cluster" {
  source = "../modules/aks-cluster"

  # Azure Configuration
  azure_region              = "westeurope"

  # SSL Certificate Configuration
  letsencrypt_email         = var.letsencrypt_email

  # Cluster Configuration
  cluster_name              = var.azure_cluster_name
  cluster_vm_size           = "Standard_B2s"  # Low memory (4GB) Burst VM (2CPU)
  cluster_vm_disk_size      = 30              # Max size of it's Ephemeral disk
  cluster_vm_min_node_count = 1
  cluster_vm_max_node_count = var.sonarqube_replica_count > 0 ? 2 : 1 # Lets the cluster autoscale to a 2nd node while SonarQube is turned on
  cluster_vm_max_pods_count = 40              # Give a bit more space
  cluster_worker_node_count = 0
}

# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "azure_cluster_name" {
  description = "The name of the Azure Kubernetes cluster."
  type        = string
  default     = "aks-1-payg-westeu-prod"
}
variable "letsencrypt_email" {
  description = "The email address used for Let's Encrypt registration."
  type        = string
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "azure_load_balancer_external_ip" {
  description = "The external IP address of the Load Balancer"
  value       = module.aks_cluster.azure_load_balancer_external_ip
}

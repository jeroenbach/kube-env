module "aks-cluster" {
  source         = "../../modules/azure/aks-cluster"
  cluster_name   = "aks-vse-westeu-dev"
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count
  vm_size        = "Standard_D8s_v3" # Expensive fast machine (don't forget to destroy after use)
  vm_disk_size   = 128               # Max size of it's Ephemeral disk
}

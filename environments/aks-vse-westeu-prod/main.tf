module "aks-cluster" {
  source         = "../../modules/azure/aks-cluster"
  cluster_name   = "aks-vse-westeu-prod"
  min_node_count = 1
  max_node_count = 1
  vm_size        = "Standard_B2s" # Low memory (4GB) Burst VM (2CPU)
  vm_disk_size   = 30             # Max size of it's Ephemeral disk
}

resource "azurerm_resource_group" "aks_cluster" {
  name     = "rg-${var.cluster_name}"
  location = var.azure_region
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.cluster_name
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.aks_cluster.name
  node_resource_group = "rg-nodes-${var.cluster_name}"
  dns_prefix          = "aks"

  default_node_pool {
    name                 = "default"
    auto_scaling_enabled = true
    max_count            = var.cluster_vm_max_node_count
    min_count            = var.cluster_vm_min_node_count
    vm_size              = var.cluster_vm_size
    os_disk_size_gb      = var.cluster_vm_disk_size
    os_disk_type         = "Ephemeral" # Cheaper and faster than managed disks
    max_pods             = var.cluster_vm_max_pods_count

    # in case some values change that triggers a re-creation of the node pool
    temporary_name_for_rotation = "temp" 
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = var.load_balancer_enabled ? "loadBalancer" : "managedNATGateway"
  }

  depends_on = [
    azurerm_resource_group.aks_cluster
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "additional_worker_pool" {
  name                  = "worker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  vm_size              = "Standard_D8s_v3"  # Expensive fast machine (don't forget to destroy after use)
  node_count           = var.cluster_worker_node_count
  
  # Optional configurations
  auto_scaling_enabled = false
  os_disk_type        = "Ephemeral"
  max_pods            = 90

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }
  
  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}


// Whenever we make changes to the AKS cluster, we also set the current context to the cluster
resource "null_resource" "set_kube_context" {
  provisioner "local-exec" {
    command = <<EOT
      # We can use the Azure CLI to get the credentials for the AKS cluster
      #az aks get-credentials --resource-group rg-${azurerm_kubernetes_cluster.aks_cluster.name} --name ${azurerm_kubernetes_cluster.aks_cluster.name} --overwrite-existing

      # Or we get it from the Terraform state and add it to the kubeconfig
      echo '${azurerm_kubernetes_cluster.aks_cluster.kube_config_raw}' > ~/.kube/config
      export KUBECONFIG=~/.kube/config
      kubectl config use-context ${azurerm_kubernetes_cluster.aks_cluster.name}
    EOT
  }

  // Always set the kube context when running apply
  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}
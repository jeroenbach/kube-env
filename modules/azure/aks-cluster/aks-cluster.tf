
resource "azurerm_resource_group" "aks-cluster" {
  name     = "rg-${var.cluster_name}"
  location = "westeurope"
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                = var.cluster_name
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.aks-cluster.name
  node_resource_group = "rg-nodes-${var.cluster_name}"
  dns_prefix          = "aks"

  default_node_pool {
    name                 = "default"
    auto_scaling_enabled = true
    max_count            = var.max_node_count
    min_count            = var.min_node_count
    vm_size              = var.vm_size
    os_disk_size_gb      = var.vm_disk_size
    os_disk_type         = "Ephemeral" # Cheaper and faster than managed disks
    max_pods             = var.max_pods_count
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
    load_balancer_sku = "basic" # cheaper option, but allows only 1 nodepool
  }

  depends_on = [
    azurerm_resource_group.aks-cluster
  ]
}

// Whenever we make changes to the AKS cluster, we also set the current context to the cluster
resource "null_resource" "set_kube_context" {
  provisioner "local-exec" {
    command = <<EOT
      # We can use the Azure CLI to get the credentials for the AKS cluster
      #az aks get-credentials --resource-group rg-${azurerm_kubernetes_cluster.aks-cluster.name} --name ${azurerm_kubernetes_cluster.aks-cluster.name} --overwrite-existing

      # Or we get it from the Terraform state and add it to the kubeconfig
      echo '${azurerm_kubernetes_cluster.aks-cluster.kube_config_raw}' > ~/.kube/config
      export KUBECONFIG=~/.kube/config
      kubectl config use-context ${azurerm_kubernetes_cluster.aks-cluster.name}
    EOT
  }

  // Always set the kube context when running apply
  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [azurerm_kubernetes_cluster.aks-cluster]
}

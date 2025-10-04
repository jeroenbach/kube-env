# Trigger recreation when snapshot IDs change
resource "null_resource" "snapshot_trigger" {
  triggers = {
    snapshot = var.snapshot_id
  }
}

resource "azurerm_managed_disk" "create" {
  name                 = var.pv_name
  location             = var.azure_location
  resource_group_name  = var.azure_resource_group_name
  storage_account_type = "StandardSSD_LRS"
  create_option        = var.snapshot_id != null && var.snapshot_id != "" ? "Copy" : "Empty"
  source_resource_id   = var.snapshot_id != null && var.snapshot_id != "" ? var.snapshot_id : null
  disk_size_gb         = var.disk_size_gb

  lifecycle {
    replace_triggered_by = [
      null_resource.snapshot_trigger
    ]

    # This prevents Terraform from deleting the disk when the resource is destroyed
    # in case you want to add this security, uncomment the line below
    # prevent_destroy = true
  }
}

resource "kubernetes_persistent_volume" "create" {
  metadata {
    name = var.pv_name
  }
  spec {
    capacity = {
      storage = "${var.disk_size_gb}Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      azure_disk {
        disk_name     = azurerm_managed_disk.create.name
        data_disk_uri = azurerm_managed_disk.create.id
        caching_mode  = "None"
        kind          = "Managed"
      }
    }
    storage_class_name = "default" # Ensure this matches the PVC
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.snapshot_trigger
    ]
  }

  depends_on = [azurerm_managed_disk.create]
}

resource "kubernetes_persistent_volume_claim" "create" {
  metadata {
    name      = var.pvc_name
    namespace = var.pvc_namespace

  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${var.disk_size_gb}Gi"
      }
    }
    volume_name        = kubernetes_persistent_volume.create.metadata[0].name
    storage_class_name = "default" # Ensure this matches the PV
  }

  lifecycle {
    replace_triggered_by = [
      null_resource.snapshot_trigger
    ]
  }

  depends_on = [kubernetes_persistent_volume.create]
}

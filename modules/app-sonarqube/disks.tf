module "create_pv_sonarqube_data" {
  source                    = "../persistent-azure-disk-volume"
  snapshot_id               = var.sonarqube_restore_snapshot_id
  azure_location            = var.azure_disk_location
  pvc_namespace             = var.namespace
  pv_name                   = "pv-disk-${var.name}-data-0"
  pvc_name                  = "pvc-disk-${var.name}-data-0"
  azure_resource_group_name = var.azure_disk_resource_group_name
  disk_size_gb              = var.sonarqube_data_disk_size # Holds SonarQube's data, extensions and logs

  depends_on = [kubernetes_namespace.sonarqube]
}

module "create_pv_postgresql" {
  source                    = "../persistent-azure-disk-volume"
  snapshot_id               = var.postgresql_restore_snapshot_id
  azure_location            = var.azure_disk_location
  pvc_namespace             = var.namespace
  pv_name                   = "pv-disk-${var.name}-postgresql-0"
  pvc_name                  = "pvc-disk-${var.name}-postgresql-0"
  azure_resource_group_name = var.azure_disk_resource_group_name
  disk_size_gb              = var.postgresql_data_disk_size

  depends_on = [kubernetes_namespace.sonarqube]
}

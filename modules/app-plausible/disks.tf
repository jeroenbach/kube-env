module "create_pv_postgresql" {
  source                    = "../persistent-azure-disk-volume"
  snapshot_id               = var.postgresql_restore_snapshot_id
  azure_location            = var.azure_disk_location
  pvc_namespace             = var.namespace
  pv_name                   = "pv-disk-${var.name}-postgresql-0"
  pvc_name                  = "pvc-disk-${var.name}-postgresql-0"
  azure_resource_group_name = var.azure_disk_resource_group_name
  disk_size_gb              = var.plausible_config_disk_size # Keep this equal to the size defined in the plausible helm chart

  depends_on = [kubernetes_namespace.plausible_analytics]
}

module "create_pv_clickhouse" {
  source                    = "../persistent-azure-disk-volume"
  snapshot_id               = var.clickhouse_restore_snapshot_id
  azure_location            = var.azure_disk_location
  pvc_namespace             = var.namespace
  pv_name                   = "pv-disk-${var.name}-clickhouse-0"
  pvc_name                  = "pvc-disk-${var.name}-clickhouse-0"
  azure_resource_group_name = var.azure_disk_resource_group_name
  disk_size_gb              = var.plausible_data_disk_size # Keep this equal to the size defined in the plausible helm chart

  depends_on = [kubernetes_namespace.plausible_analytics]
}

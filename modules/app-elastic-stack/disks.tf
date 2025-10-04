module "create_pv_elasticsearch" {
  source                    = "../persistent-azure-disk-volume"
  snapshot_id               = var.elasticsearch_restore_snapshot_id
  azure_location            = var.azure_disk_location
  pvc_namespace             = "elastic-stack"
  pv_name                   = "pv-elasticsearch-data-elasticsearch-es-default-0"
  pvc_name                  = "elasticsearch-data-elasticsearch-es-default-0"
  azure_resource_group_name = var.azure_disk_resource_group_name
  disk_size_gb              = var.elasticsearch_data_disk_size # Keep this equal to the size defined in the plausible helm chart

  depends_on = [kubernetes_namespace.elastic-stack]
}

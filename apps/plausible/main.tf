resource "kubernetes_namespace" "plausible_analytics" {
  metadata {
    name = "plausible-analytics"
  }
}

module "create-pv-postgresql" {
  source              = "../../modules/azure/create-persistent-volume"
  snapshot_id         = var.postgresql_source_resource_id
  location            = var.location
  pvc_namespace       = "plausible-analytics"
  pv_name             = "pv-disk-plausible-postgresql-0"
  pvc_name            = "pvc-disk-plausible-postgresql-0"
  resource_group_name = var.resource_group_name
  disk_size_gb        = 1 # Keep this equal to the size defined in the plausible helm chart

  depends_on = [kubernetes_namespace.plausible_analytics]
}
module "create-pv-clickhouse" {
  source              = "../../modules/azure/create-persistent-volume"
  snapshot_id         = var.clickhouse_source_resource_id
  location            = var.location
  pvc_namespace       = "plausible-analytics"
  pv_name             = "pv-disk-plausible-clickhouse-0"
  pvc_name            = "pvc-disk-plausible-clickhouse-0"
  resource_group_name = var.resource_group_name
  disk_size_gb        = 8 # Keep this equal to the size defined in the plausible helm chart

  depends_on = [kubernetes_namespace.plausible_analytics]
}

resource "helm_release" "plausible" {
  name             = "plausible-analytics"
  namespace        = "plausible-analytics"
  repository       = "https://imio.github.io/helm-charts"
  chart            = "plausible-analytics"
  create_namespace = true
  version          = "0.3.3"


  values = [
    <<EOF
baseURL: "http://${var.plausible_dns}"

postgresql:
  primary:
    persistence:
      enabled: true
      existingClaim: pvc-disk-plausible-postgresql-0
      size: 1Gi # This database is only used for settings and user data, so it doesn't need to be very large

clickhouse:
  persistence:
    enabled: true
    existingClaim: pvc-disk-plausible-clickhouse-0
    size: 8Gi # This database is used for storing all the analytics data, so it needs to be larger

ingress:
  enabled: true
  annotations: 
    cert-manager.io/cluster-issuer: "letsencrypt-production"
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
  className: nginx
  hosts:
    - ${var.plausible_dns}
  path: /
  tls: 
    - secretName: letsencrypt-production
      hosts:
        - ${var.plausible_dns}
EOF
  ]

  depends_on = [module.create-pv-postgresql, module.create-pv-clickhouse]
}

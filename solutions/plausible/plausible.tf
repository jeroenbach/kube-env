resource "helm_release" "plausible" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://imio.github.io/helm-charts"
  chart            = "plausible-analytics"
  create_namespace = true
  # version          = "0.3.3"  # plausible v2.1.4, postgres v13.3 (data v15), clickhouse v23.3.9 
  # version          = "0.4.2"  # plausible v3.0.1, postgres v17.6.0, clickhouse v24.12.3.47
  version            = var.chart_version

  values = [
    <<EOF
baseURL: "http://${var.plausible_dns}"

# Override the database URLs to use the correct service names
databaseURL: "postgres://postgres:postgres@${var.name}-postgresql:5432/plausible_db"
clickhouseDatabaseURL: "http://clickhouse:password@${var.name}-clickhouse:8123/plausible_events_db"

postgresql:
  primary:
    persistence:
      enabled: true
      existingClaim: pvc-disk-${var.name}-postgresql-0
      size: ${var.plausible_config_disk_size}Gi # This database is only used for settings and user data, so it doesn't need to be very large
    resources:
      requests:
        memory: 50Mi

clickhouse:
  persistence:
    enabled: true
    existingClaim: pvc-disk-${var.name}-clickhouse-0
    size: ${var.plausible_data_disk_size}Gi # This database is used for storing all the analytics data, so it needs to be larger
  resources:
    requests:
      memory: 300Mi

resources:
  requests:
    memory: 300Mi

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
  pathType: Prefix
  tls: 
    - secretName: letsencrypt-production
      hosts:
        - ${var.plausible_dns}
EOF
  ]

  depends_on = [module.create_pv_postgresql, module.create_pv_clickhouse]
}

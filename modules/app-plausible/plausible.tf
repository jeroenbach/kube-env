# Trigger recreation when snapshot IDs change
resource "null_resource" "snapshot_trigger" {
  triggers = {
    postgresql_snapshot = var.postgresql_restore_snapshot_id
    clickhouse_snapshot = var.clickhouse_restore_snapshot_id
  }
}

resource "helm_release" "plausible" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://imio.github.io/helm-charts"
  chart            = "plausible-analytics"
  create_namespace = true
  version          = var.chart_version

  lifecycle {
    replace_triggered_by = [
      null_resource.snapshot_trigger
    ]
  }

  # Unfortunately the image from the chart is not available anymore
  # so we have to override it here
  values = [
    <<EOF
baseURL: "https://${var.plausible_dns}"

# Override the database URLs to use the correct service names
databaseURL: "postgres://postgres:postgres@${var.name}-postgresql:5432/plausible_db"
clickhouseDatabaseURL: "http://clickhouse:password@${var.name}-clickhouse:8123/plausible_events_db"

%{if var.google_client_id != null && var.google_client_secret != null~}
# Google OAuth Configuration
google:
  enabled: true
  clientID: "${var.google_client_id}"
  clientSecret: "${var.google_client_secret}"
%{endif~}

postgresql:
  primary:
    persistence:
      enabled: true
      existingClaim: pvc-disk-${var.name}-postgresql-0
      size: ${var.plausible_config_disk_size}Gi # This database is only used for settings and user data, so it doesn't need to be very large
    resources:
      requests:
        memory: 75Mi

clickhouse:
  persistence:
    enabled: true
    existingClaim: pvc-disk-${var.name}-clickhouse-0
    size: ${var.plausible_data_disk_size}Gi # This database is used for storing all the analytics data, so it needs to be larger
  resources:
    requests:
      memory: 400Mi

resources:
  requests:
    memory: 350Mi

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

  depends_on = [
    kubernetes_namespace.plausible_analytics,
    module.create_pv_postgresql,
    module.create_pv_clickhouse
  ]
}

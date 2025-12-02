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
      memory: 1000Mi  # Increased to match actual usage
    limits:
      # When Kubernetes sets a memory limit (1229Mi in our case), the container sees that limit as its total available memory through cgroups
      # ClickHouse reads this cgroup limit and calculates 75% of 1229Mi (≈922Mi), not 75% of the node's total memory
      # If you didn't set a limit, the container would see the entire node's memory (4GB), and ClickHouse would try to use 75% of that (3GB), which could cause issues with other pods
      memory: 1229Mi  # 1.2Gi max to stay within node capacity
  # Disable heavy system logs to prevent disk space issues (7.5GB was consumed by these logs)
  # Uses extraOverrides for inline XML configuration (Clickhouse chart 7.2.0)
  # Ref: Bundled chart at charts/clickhouse/values.yaml line 425
  logLevel: warning
  extraOverrides: |
    <clickhouse>
      <!-- Disable trace_log (was using 2.6GB) -->
      <trace_log remove="1"/>
      <!-- Disable metric_log (was using 1.9GB) -->
      <metric_log remove="1"/>
      <!-- Disable asynchronous_metric_log (was using 1.9GB) -->
      <asynchronous_metric_log remove="1"/>
      <!-- Keep query_log but with short 7-day retention -->
      <query_log>
        <database>system</database>
        <table>query_log</table>
        <partition_by>toYYYYMM(event_date)</partition_by>
        <ttl>event_date + INTERVAL 7 DAY</ttl>
      </query_log>
      <!-- Keep text_log but with short 3-day retention -->
      <text_log>
        <database>system</database>
        <table>text_log</table>
        <ttl>event_date + INTERVAL 3 DAY</ttl>
      </text_log>
    </clickhouse>

resources:
  requests:
    memory: 400Mi  # Increased for main Plausible app
  limits:
    memory: 600Mi

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

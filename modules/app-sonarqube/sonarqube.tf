# Trigger recreation when snapshot IDs change
resource "null_resource" "snapshot_trigger" {
  triggers = {
    sonarqube_snapshot  = var.sonarqube_restore_snapshot_id
    postgresql_snapshot = var.postgresql_restore_snapshot_id
  }
}

# Used to authenticate SonarQube's internal liveness/readiness probes. Not user-facing, so a
# generated value is fine - there's no login involved.
resource "random_password" "monitoring_passcode" {
  length  = 32
  special = false
}

resource "helm_release" "sonarqube" {
  name             = var.name
  namespace        = var.namespace
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  create_namespace = true
  version          = var.chart_version
  # SonarQube is slow to start: the cluster autoscaler needs ~2-3 min to provision a new node,
  # then SonarQube's JVM + internal Elasticsearch index take another 3-5 min to warm up.
  timeout = 900 # 15 minutes

  lifecycle {
    replace_triggered_by = [
      null_resource.snapshot_trigger
    ]
  }

  values = [
    <<EOF
# Run the free Community Build (the chart's default image requires a commercial Developer/Enterprise license)
community:
  enabled: true

# Scale to 0 to fully stop SonarQube (and let the extra node scale back down) when you don't need
# it, and back to 1 to spin it up again. Data is kept on the persistent disk either way.
replicaCount: ${var.sonarqube_replica_count}

persistence:
  enabled: true
  existingClaim: pvc-disk-${var.name}-data-0

resources:
  requests:
    memory: 1536Mi
    cpu: 500m
  limits:
    memory: 3072Mi
    cpu: 1000m

jdbcOverwrite:
  enabled: true
  jdbcUrl: "jdbc:postgresql://${var.name}-postgresql:5432/${var.name}"
  jdbcUsername: "${var.name}"
  jdbcSecretName: "${kubernetes_secret.postgresql.metadata[0].name}"
  jdbcSecretPasswordKey: "POSTGRES_PASSWORD"

# Required by the chart, otherwise the pod never reports ready (probes need to authenticate)
monitoringPasscode: "${random_password.monitoring_passcode.result}"

ingress:
  enabled: true
  ingressClassName: nginx
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-production"
    kubernetes.io/tls-acme: "true"
  hosts:
    - name: ${var.sonarqube_dns}
  tls:
    - secretName: letsencrypt-production
      hosts:
        - ${var.sonarqube_dns}
EOF
  ]

  depends_on = [
    kubernetes_namespace.sonarqube,
    module.create_pv_sonarqube_data,
    kubernetes_service.postgresql
  ]
}

# SonarQube's official Helm chart doesn't bundle a database (unlike the Plausible chart), so we
# run a small, plain PostgreSQL deployment ourselves, backed by the persistent disk in disks.tf.
#
# Replicas follow `var.sonarqube_replica_count` so both scale up and down together. Data is safe
# either way — PostgreSQL flushes cleanly on shutdown, and the disk persists independently of the
# pod. SonarQube may log a few connection errors (~10-30s) while it waits for Postgres to finish
# starting up, but retries automatically without any manual intervention.

resource "random_password" "postgresql" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "postgresql" {
  metadata {
    name      = "${var.name}-postgresql"
    namespace = var.namespace
  }

  data = {
    POSTGRES_DB       = var.name
    POSTGRES_USER     = var.name
    POSTGRES_PASSWORD = random_password.postgresql.result
  }

  depends_on = [kubernetes_namespace.sonarqube]
}

resource "kubernetes_deployment" "postgresql" {
  metadata {
    name      = "${var.name}-postgresql"
    namespace = var.namespace
    labels    = { app = "${var.name}-postgresql" }
  }

  spec {
    replicas = var.sonarqube_replica_count

    selector {
      match_labels = { app = "${var.name}-postgresql" }
    }

    # Recreate (not RollingUpdate): the disk is ReadWriteOnce, so two pods can't mount it at once
    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = { app = "${var.name}-postgresql" }
      }

      spec {
        container {
          name  = "postgresql"
          image = "postgres:16-alpine"

          port {
            container_port = 5432
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata" # subdirectory, so the disk's lost+found dir doesn't confuse postgres
          }

          env_from {
            secret_ref {
              name = kubernetes_secret.postgresql.metadata[0].name
            }
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/postgresql/data"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "50m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "250m"
            }
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = "pvc-disk-${var.name}-postgresql-0"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.sonarqube,
    module.create_pv_postgresql,
    kubernetes_secret.postgresql
  ]
}

resource "kubernetes_service" "postgresql" {
  metadata {
    name      = "${var.name}-postgresql"
    namespace = var.namespace
  }

  spec {
    selector = { app = "${var.name}-postgresql" }

    port {
      port        = 5432
      target_port = 5432
    }
  }

  depends_on = [kubernetes_deployment.postgresql]
}

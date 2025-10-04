resource "kubernetes_namespace" "plausible_analytics" {
  metadata {
    name = var.namespace
  }
}
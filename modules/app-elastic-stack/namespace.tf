resource "kubernetes_namespace" "elastic-system" {
  metadata {
    name = "elastic-system"
  }
}
resource "kubernetes_namespace" "elastic-stack" {
  metadata {
    name = "elastic-stack"
  }
}
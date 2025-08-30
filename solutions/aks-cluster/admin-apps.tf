# A few modules that are needed by other apps/modules or helpful for cluster administration
module "ingress_nginx" {
  source = "../../modules/helm/ingress-nginx"
  service_type = var.load_balancer_enabled ? "LoadBalancer" : "ClusterIP"

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}

module "cert_manager" {
  source = "../../modules/helm/cert-manager"

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}

module "letsencrypt_cert_issuer" {
  source            = "../../modules/helm/letsencrypt-cert-issuer"
  letsencrypt_email = var.letsencrypt_email

  depends_on = [
    module.cert_manager
  ]
}

module "rancher" {
  source            = "../../modules/helm/rancher"
  count             = var.rancher_enabled ? 1 : 0
  rancher_dns       = var.rancher_dns
  letsencrypt_email = var.letsencrypt_email

  depends_on = [
    module.cert_manager,
    module.ingress_nginx
  ]
}

module "grafana" {
  source = "../../modules/helm/grafana"
  count  = var.grafana_enabled ? 1 : 0

  depends_on = [
    azurerm_kubernetes_cluster.aks_cluster
  ]
}

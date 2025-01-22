# A few modules that are needed by other apps/modules or helpful for cluster administration
module "ingress_nginx" {
  source = "../../modules/helm/ingress-nginx"

  depends_on = [
    module.aks-cluster
  ]
}

module "cert-manager" {
  source = "../../modules/helm/cert-manager"

  depends_on = [
    module.aks-cluster
  ]
}

module "letsencrypt-cert-issuer" {
  source            = "../../modules/helm/letsencrypt-cert-issuer"
  letsencrypt_email = var.letsencrypt_email

  depends_on = [
    module.cert-manager
  ]
}

module "rancher" {
  source            = "../../modules/helm/rancher"
  rancher_dns       = var.rancher_dns
  letsencrypt_email = var.letsencrypt_email
  count             = var.rancher_enabled ? 1 : 0

  depends_on = [
    module.cert-manager,
    module.ingress_nginx
  ]
}

module "grafana" {
  source = "../../modules/helm/grafana"
  count  = var.grafana_enabled ? 1 : 0

  depends_on = [
    module.aks-cluster
  ]
}

resource "helm_release" "letsencrypt_cert_issuer" {
  name             = "letsencrypt-cert-issuer"
  chart            = "../../../helm-charts/letsencrypt-cert-issuer"
  namespace        = "cert-manager"
  create_namespace = true

  set = [
    {
      name  = "letsencrypt.email"
      value = var.letsencrypt_email
    }
  ]
}

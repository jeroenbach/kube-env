resource "helm_release" "rancher" {
  name             = "rancher"
  namespace        = "cattle-system"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  create_namespace = true

  values = [
    <<EOF
${var.rancher_dns != null ? "hostname: ${var.rancher_dns}" : ""}
ingress:
  enabled: ${var.rancher_dns == null ? false : true}
  tls:
    source: letsEncrypt
  ingressClassName: nginx
letsEncrypt:
  email: ${var.letsencrypt_email}
  ingress:
    class: nginx
EOF
  ]
}

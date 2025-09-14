resource "helm_release" "rancher" {
  name             = "rancher"
  namespace        = "cattle-system"
  repository       = "https://releases.rancher.com/server-charts/stable"
  chart            = "rancher"
  version          = "2.12.1"
  create_namespace = true
  cleanup_on_fail  = true
  force_update     = true
  
  values = [
    <<EOF
${var.rancher_dns != null ? "hostname: ${var.rancher_dns}" : ""}
replicas: 1
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

# Cleanup resource to handle stuck namespace during destroy
resource "null_resource" "rancher_cleanup" {
  triggers = {
    rancher_release = helm_release.rancher.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl patch namespace cattle-system -p '{"metadata":{"finalizers":[]}}' --type=merge || true
      kubectl delete namespace cattle-system --force --grace-period=0 || true
    EOT
    on_failure = continue
  }

  depends_on = [helm_release.rancher]
}

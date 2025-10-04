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

  depends_on = [ module.aks_cluster ]
}

resource "cloudflare_dns_record" "record" {
  count   = var.rancher_dns != null && var.rancher_dns != "" && var.cloudflare_api_token != null && var.cloudflare_api_token != "" && var.cloudflare_zone_id != null  && var.cloudflare_zone_id != "" ? 1 : 0
  zone_id = var.cloudflare_zone_id
  name    = var.rancher_dns
  content = module.aks_cluster.azure_load_balancer_external_ip
  type    = "A"
  ttl     = 1
  proxied = false

  depends_on = [ module.aks_cluster ]
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

# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "rancher_dns" {
  description = "The DNS name for the Rancher server. If left empty we don't expose Rancher externally."
  type        = string
  default     = null
}

# variable "letsencrypt_email" {
#   description = "The email address for Let's Encrypt notifications"
#   type        = string
# }


data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

resource "cloudflare_record" "plausible" {
  count           = var.plausible_dns != null && var.cloudflare_zone_id != null ? 1 : 0
  zone_id         = var.cloudflare_zone_id
  name            = replace(var.plausible_dns, ".${var.root_domain}", "")
  content         = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
  type            = "A"
  ttl             = 1 # Set TTL to "auto"
  proxied         = false
  allow_overwrite = true

}

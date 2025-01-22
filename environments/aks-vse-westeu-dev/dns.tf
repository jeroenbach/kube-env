resource "cloudflare_record" "rancher" {
  # Only create the cloudflare record if rancher_dns is set
  count           = var.rancher_enabled == true && var.rancher_dns != null && var.cloudflare_zone_id != null ? 1 : 0
  zone_id         = var.cloudflare_zone_id
  name            = var.rancher_dns
  content         = module.ingress_nginx.external_ip
  type            = "A"
  ttl             = 1 # Set TTL to "auto"
  proxied         = false
  allow_overwrite = true

  depends_on = [module.ingress_nginx]
}

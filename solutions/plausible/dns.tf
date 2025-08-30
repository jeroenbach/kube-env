module "plausible_dns" {
  source = "../../modules/cloudflare/dns-record"
  
  enabled               = var.plausible_dns != null && var.cloudflare_api_token != null && var.cloudflare_zone_id != null
  zone_id               = var.cloudflare_zone_id
  name                  = var.plausible_dns

  # Pick whichever one is available and create the record accordingly
  load_balancer_enabled = var.load_balancer_enabled
  tunnel_enabled        = var.tunnel_enabled
  record_content        = var.record_content

  depends_on = [
    helm_release.plausible,
  ]
}
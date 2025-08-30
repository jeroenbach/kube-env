module "rancher_dns" {
  source = "../../modules/cloudflare/dns-record"
  
  enabled               = var.rancher_enabled && var.rancher_dns != null && var.cloudflare_api_token != null && var.cloudflare_zone_id != null
  zone_id               = var.cloudflare_zone_id
  name                  = var.rancher_dns

  # Pick whichever one is available and create the record accordingly
  load_balancer_enabled = var.load_balancer_enabled
  tunnel_enabled        = var.tunnel_enabled
  record_content        = var.load_balancer_enabled ? try(module.ingress_nginx.external_ip, null) : try(module.cloudflare_tunnel[0].tunnel_cname, null)

  depends_on = [
    module.ingress_nginx,
    module.cloudflare_tunnel
  ]
}
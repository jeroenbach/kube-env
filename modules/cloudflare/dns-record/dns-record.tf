# Create DNS record - single resource that handles both A and CNAME
resource "cloudflare_dns_record" "record" {
  count = var.enabled && (var.load_balancer_enabled || var.tunnel_enabled) ? 1 : 0

  zone_id = var.zone_id
  name    = var.name
  content = var.record_content
  type    = var.load_balancer_enabled ? "A" : "CNAME"
  ttl     = var.ttl
  proxied = var.proxied
}
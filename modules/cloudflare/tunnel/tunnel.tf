resource "random_password" "tunnel_secret" {
  length  = 32
  special = true
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.account_id
  name          = var.tunnel_name
  tunnel_secret = base64encode(random_password.tunnel_secret.result)
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
  account_id = var.account_id

  config     = {
    ingress   = [
      {
        # Route ALL traffic to ingress controller
        service  = var.ingress_service
        origin_request = {
          no_tls_verify = true
        }
      }
    ]
  }
}
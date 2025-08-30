output "tunnel_id" {
  description = "The ID of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
}

output "tunnel_name" {
  description = "The name of the Cloudflare tunnel"
  value       = cloudflare_zero_trust_tunnel_cloudflared.tunnel.name
}

output "tunnel_cname" {
  description = "The CNAME of the Cloudflare tunnel"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
}

output "tunnel_secret" {
  description = "The tunnel secret (sensitive)"
  value       = base64encode(random_password.tunnel_secret.result)
  sensitive   = true
}


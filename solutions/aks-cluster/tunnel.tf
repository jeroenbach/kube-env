module "cloudflare_tunnel" {
  count  = var.tunnel_enabled && var.cloudflare_account_id != null ? 1 : 0
  source = "../../modules/cloudflare/tunnel"
  
  account_id   = var.cloudflare_account_id
  tunnel_name  = "${var.cluster_name}-tunnel"
  ingress_service = "https://ingress-nginx-controller.ingress-nginx.svc.cluster.local"

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

module "cloudflared" {
  source = "../../modules/helm/cloudflared"
  count  = var.tunnel_enabled ? 1 : 0

  account_id         = var.cloudflare_account_id
  tunnel_id          = module.cloudflare_tunnel[0].tunnel_id
  tunnel_name        = module.cloudflare_tunnel[0].tunnel_name
  tunnel_credentials = module.cloudflare_tunnel[0].tunnel_secret
  ingress_service    = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
  replica_count      = 1

  depends_on = [
    module.ingress_nginx,
    module.cloudflare_tunnel
  ]
}

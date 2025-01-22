output "rancher_dns" {
  value = var.plausible_dns
}

output "external_ip" {
  value = data.kubernetes_service.ingress_nginx.status.0.load_balancer.0.ingress.0.ip
}

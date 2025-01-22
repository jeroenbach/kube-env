
output "external_ip" {
  value = module.ingress_nginx.external_ip
}

output "kube_config" {
  value     = module.aks-cluster.kube_config
  sensitive = true
}

output "external_ip" {
  value = data.external.ingress_external_ip.result.ip != "" ? data.external.ingress_external_ip.result.ip : null
}

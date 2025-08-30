resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.13.1"
  create_namespace = true

  values = [
    <<EOF
controller:
  service:
    type: ${var.service_type}
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
    ${var.service_type == "LoadBalancer" ? "externalTrafficPolicy: Local" : ""}
EOF
  ]
}

resource "null_resource" "wait_for_ingress_nginx" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..30}; do
        kubectl get svc -n ingress-nginx ${helm_release.ingress_nginx.name}-controller && sleep 30 && break || sleep 30;
      done
    EOT
  }

  depends_on = [helm_release.ingress_nginx]
}

# Get external IP using kubectl
data "external" "ingress_external_ip" {
  program = ["bash", "-c", <<EOT
    if [ "${var.service_type}" = "LoadBalancer" ]; then
      EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ${helm_release.ingress_nginx.name}-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
      echo "{\"ip\":\"$EXTERNAL_IP\"}"
    else
      echo "{\"ip\":null}"
    fi
  EOT
  ]
  
  depends_on = [null_resource.wait_for_ingress_nginx]
}

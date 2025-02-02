resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  create_namespace = true

  values = [
    <<EOF
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
    externalTrafficPolicy: Local
EOF
  ]
}

resource "null_resource" "wait_for_ingress_nginx" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..30}; do
        kubectl get svc -n ingress-nginx ${helm_release.ingress_nginx.name}-controller && sleep 10 && break || sleep 10;
      done
    EOT
  }

  depends_on = [helm_release.ingress_nginx]
}

# Fetch the service details
data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "${helm_release.ingress_nginx.name}-controller"
    namespace = helm_release.ingress_nginx.namespace
  }

  depends_on = [null_resource.wait_for_ingress_nginx]
}

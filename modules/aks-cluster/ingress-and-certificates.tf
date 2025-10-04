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
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
    externalTrafficPolicy: Local
EOF
  ]

  depends_on = [
    null_resource.set_kube_context
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
    EXTERNAL_IP=$(kubectl get svc -n ingress-nginx ${helm_release.ingress_nginx.name}-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    echo "{\"ip\":\"$EXTERNAL_IP\"}"
  EOT
  ]
  
  depends_on = [null_resource.wait_for_ingress_nginx]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  create_namespace = true
  version          = "1.16.3"

  set = [ {
    name  = "crds.enabled"
    value = "true"
  } ]
  
  depends_on = [
    null_resource.set_kube_context
  ]
}

resource "helm_release" "letsencrypt_cert_issuer" {
  name             = "letsencrypt-cert-issuer"
  chart            = "../helm-charts/letsencrypt-cert-issuer"
  namespace        = "cert-manager"
  create_namespace = true

  set = [
    {
      name  = "letsencrypt.email"
      value = var.letsencrypt_email
    }
  ]

  depends_on = [
    helm_release.cert_manager
  ]
}

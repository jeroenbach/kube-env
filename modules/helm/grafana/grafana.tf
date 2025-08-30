resource "helm_release" "grafana" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "77.1.0"
  create_namespace = true
  
  values = [
    <<EOF
prometheus:
  prometheusSpec:
    resources:
      requests:
        memory: 450Mi
grafana:
  resources:
    requests:
      memory: 320Mi
EOF
  ]
}

# Install ECK Operator first
resource "helm_release" "eck_operator" {
  name             = "elastic-operator"
  namespace        = "elastic-system"
  repository       = "https://helm.elastic.co"
  chart            = "eck-operator"
  version          = "3.1.0"
  create_namespace = false

  values = [
    <<EOF
resources:
  requests:
    memory: 256Mi
    cpu: 100m
  limits:
    memory: 512Mi
    cpu: 500m
EOF
  ]

  depends_on = [ kubernetes_namespace.elastic-system ]
}

# Wait for CRDs to be ready
resource "null_resource" "wait_for_eck_crds" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for ECK CRDs to be installed..."
      for i in {1..30}; do
        if kubectl get crd elasticsearches.elasticsearch.k8s.elastic.co 2>/dev/null && \
           kubectl get crd kibanas.kibana.k8s.elastic.co 2>/dev/null; then
          echo "ECK CRDs are ready"
          break
        fi
        echo "Waiting for CRDs... ($i/30)"
        sleep 10
      done
    EOT
  }

  depends_on = [helm_release.eck_operator]
}

# Deploy Elasticsearch and Kibana
resource "helm_release" "elastic_stack" {
  name             = "eck-stack"
  namespace        = "elastic-stack"
  repository       = "https://helm.elastic.co"
  chart            = "eck-stack"
  version          = "0.16.0"
  create_namespace = false

  values = [
    <<EOF
# Disable operator installation (already installed)
eck-operator:
  enabled: false

# Elasticsearch Configuration
eck-elasticsearch:
  enabled: true
  fullnameOverride: elasticsearch
  version: 8.16.1
  nodeSets:
  - name: default
    count: 1
    config:
      node.store.allow_mmap: false
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 1Gi
              cpu: 500m
            limits:
              memory: 2Gi
              cpu: 1000m
          volumeMounts:
          - name: elasticsearch-data
            mountPath: /usr/share/elasticsearch/data
        volumes:
        - name: elasticsearch-data
          persistentVolumeClaim:
            claimName: elasticsearch-data-elasticsearch-es-default-0

# Kibana Configuration
eck-kibana:
  enabled: true
  fullnameOverride: kibana
  version: 8.16.1
  count: 1
  spec:
    config:
      server.publicBaseUrl: ${var.kibana_dns != null && var.kibana_dns != "" ? "https://${var.kibana_dns}" : ""}
    podTemplate:
      spec:
        containers:
        - name: kibana
          resources:
            requests:
              memory: 512Mi
              cpu: 200m
            limits:
              memory: 1Gi
              cpu: 500m
    http:
      tls:
        selfSignedCertificate:
          disabled: true
EOF
  ]

  depends_on = [
    helm_release.eck_operator,
    null_resource.wait_for_eck_crds,
    module.create_pv_elasticsearch
  ]
}

# Wait for Elasticsearch to be ready
resource "null_resource" "wait_for_elasticsearch" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..60}; do
        kubectl get secret elasticsearch-es-elastic-user -n elastic-stack 2>/dev/null && break || sleep 10;
      done
    EOT
  }

  depends_on = [helm_release.elastic_stack, kubernetes_namespace.elastic-system]
}

# Get Elasticsearch password using kubectl
data "external" "elasticsearch_password" {
  program = ["bash", "-c", <<EOT
    PASSWORD=$(kubectl get secret elasticsearch-es-elastic-user -n elastic-stack -o jsonpath='{.data.elastic}' 2>/dev/null | base64 -d || echo "")
    echo "{\"password\":\"$PASSWORD\"}"
  EOT
  ]

  depends_on = [null_resource.wait_for_elasticsearch]
}

# Ingress for Kibana
resource "kubernetes_ingress_v1" "kibana" {
  count = var.kibana_dns != null && var.kibana_dns != "" ? 1 : 0

  metadata {
    name      = "kibana"
    namespace = "elastic-stack"
    annotations = {
      "cert-manager.io/cluster-issuer"           = "letsencrypt-production"
      "kubernetes.io/ingress.class"              = "nginx"
      "kubernetes.io/tls-acme"                   = "true"
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true"
    }
  }

  spec {
    ingress_class_name = "nginx"

    tls {
      hosts       = [var.kibana_dns]
      secret_name = "letsencrypt-production"
    }

    rule {
      host = var.kibana_dns

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "kibana-kb-http"
              port {
                number = 5601
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.elastic_stack]
}

# Cleanup resource to handle stuck namespace during destroy
resource "null_resource" "elastic_cleanup" {
  triggers = {
    elastic_release = helm_release.elastic_stack.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      kubectl patch namespace elastic-stack -p '{"metadata":{"finalizers":[]}}' --type=merge || true
      kubectl delete namespace elastic-stack --force --grace-period=0 || true
    EOT
    on_failure = continue
  }

  depends_on = [helm_release.elastic_stack]
}

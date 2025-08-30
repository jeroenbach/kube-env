resource "helm_release" "cloudflared" {
  name             = "cloudflared"
  namespace        = "cloudflared"
  repository       = "https://cloudflare.github.io/helm-charts"
  chart            = "cloudflare-tunnel"
  version          = "0.3.2"
  create_namespace = true


  values = [<<EOF
cloudflare:
  account: ${var.account_id}
  secret: ${var.tunnel_credentials}
  tunnelId: ${var.tunnel_id}
  tunnelName: ${var.tunnel_name}
  ingress:
    - service: ${var.ingress_service}

replicaCount: ${var.replica_count}
EOF
  ]

  # Remove the hardcoded 404 service from configmap
  # this way we can use a wildcard hostname to route everything to the ingress
  postrender = {
    binary_path = "bash"
    args = ["-c", <<EOT
      # Remove the hardcoded 404 service line
      sed '/- service: http_status:404/d'
    EOT
    ]
  }
}

# Wait for cloudflared deployment to be ready
resource "null_resource" "wait_for_cloudflared" {
  provisioner "local-exec" {
    command = <<EOT
      for i in {1..30}; do
        kubectl get deployment -n cloudflared cloudflared-cloudflare-tunnel && 
        kubectl rollout status deployment/cloudflared-cloudflare-tunnel -n cloudflared --timeout=300s && 
        break || sleep 10;
      done
    EOT
  }

  depends_on = [helm_release.cloudflared]
}

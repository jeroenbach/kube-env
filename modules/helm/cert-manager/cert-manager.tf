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
  
}

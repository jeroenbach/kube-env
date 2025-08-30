# Cert-Manager Helm Module

This Terraform module deploys cert-manager using Helm to provide automated TLS certificate management for Kubernetes clusters. Cert-manager automatically provisions and manages TLS certificates from various issuers including Let's Encrypt.

## Features

- Deploys official cert-manager Helm chart from Jetstack
- Automatically installs required Custom Resource Definitions (CRDs)
- Enables automatic TLS certificate provisioning and renewal
- Supports multiple certificate issuers (Let's Encrypt, private CA, etc.)
- Integrates with ingress controllers for automatic certificate attachment

## Relationship to Certificate Issuers

### **Cert-Manager vs Certificate Issuers**

- **Cert-Manager** (this module): The core certificate management engine that handles the entire certificate lifecycle
- **Certificate Issuers**: Configuration resources that tell cert-manager HOW to obtain certificates from specific providers
- **Analogy**: Cert-manager is the "certificate factory", issuers are the "instruction manuals" for different certificate providers

### **Workflow**
```
Ingress annotation (cert-manager.io/cluster-issuer: letsencrypt-production) 
    ↓
Cert-Manager detects the certificate request
    ↓ 
Cert-Manager uses the specified ClusterIssuer configuration
    ↓
Cert-Manager follows issuer rules to obtain and manage certificates
```

Cert-manager can work with multiple certificate authorities simultaneously - you just need the appropriate issuer configurations.

## Related Modules

- `letsencrypt-cert-issuer`: Creates Let's Encrypt cluster issuers for cert-manager to use
- `ingress-nginx`: NGINX ingress controller for HTTP-01 challenges
## Usage

### Basic Usage

```hcl
module "cert_manager" {
  source = "../../../modules/helm/cert-manager"
}
```

## What Gets Deployed

The module deploys cert-manager with the following configuration:

- **Namespace**: `cert-manager` (auto-created)
- **CRDs**: Automatically installed and managed
- **Components**:
  - cert-manager controller
  - cert-manager webhook
  - cert-manager cainjector

## Complete AKS Example

```hcl
# Deploy cert-manager
module "cert_manager" {
  source = "../../../modules/helm/cert-manager"
  
  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

# Deploy Let's Encrypt issuer
module "letsencrypt_issuer" {
  source = "../../../modules/helm/letsencrypt-cert-issuer"
  
  letsencrypt_email = "admin@example.com"
  
  depends_on = [module.cert_manager]
}
```

## Certificate Lifecycle

Cert-manager handles the complete certificate lifecycle:

1. **Issuance**: Automatically requests certificates from configured issuers
2. **Validation**: Handles ACME challenges (HTTP-01 or DNS-01)
3. **Storage**: Stores certificates as Kubernetes secrets
4. **Renewal**: Automatically renews certificates before expiration
5. **Updates**: Updates ingress controllers with new certificates

## Monitoring and Troubleshooting

### Check cert-manager logs
```bash
kubectl logs -n cert-manager deployment/cert-manager
```

### View certificate status
```bash
kubectl get certificates -A
kubectl describe certificate my-cert -n my-namespace
```

### View certificate requests
```bash
kubectl get certificaterequests -A
kubectl describe certificaterequest my-cert-xxx -n my-namespace
```

## Dependencies

- Kubernetes cluster with RBAC enabled
- Helm provider configured and authenticated
- Ingress controller (for HTTP-01 challenges)
- DNS provider access (for DNS-01 challenges)

## Important Notes

- cert-manager requires cluster-admin permissions during installation
- CRDs are automatically managed - don't install them separately
- Certificate renewal happens automatically (typically 30 days before expiration)
- Failed certificate requests will retry with exponential backoff
- Rate limits apply to Let's Encrypt (use staging environment for testing)

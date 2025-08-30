# Let's Encrypt Certificate Issuer Module

This Terraform module deploys Let's Encrypt ClusterIssuers using a custom Helm chart to enable automatic SSL/TLS certificate provisioning from Let's Encrypt. It creates both production and staging certificate issuers for flexible certificate management.

## Features

- Creates Let's Encrypt production ClusterIssuer for valid certificates
- Creates Let's Encrypt staging ClusterIssuer for testing
- Uses HTTP-01 challenge with NGINX ingress controller
- Automatic certificate renewal before expiration
- Configurable email for Let's Encrypt notifications

## Relationship to Cert-Manager

### **Cert-Manager vs Let's Encrypt Cert Issuer**

- **Cert-Manager**: The core certificate management engine that watches for certificate requests and manages the entire certificate lifecycle
- **Let's Encrypt Cert Issuer** (this module): Configuration that tells cert-manager HOW to get certificates from Let's Encrypt specifically
- **Analogy**: Cert-manager is the "certificate robot", this issuer is the "instruction manual" for Let's Encrypt

### **How They Work Together**
```
1. This module creates ClusterIssuer resources
    ↓
2. Ingress uses annotation: cert-manager.io/cluster-issuer: letsencrypt-production
    ↓  
3. Cert-Manager sees the annotation and certificate request
    ↓
4. Cert-Manager reads the "letsencrypt-production" ClusterIssuer config  
    ↓
5. Cert-Manager follows Let's Encrypt rules to obtain certificate
```

**Key Point**: You need BOTH modules - cert-manager to do the work, and this issuer module to tell it how to work with Let's Encrypt.

## Related Modules

- `cert-manager`: **Required dependency** - the core certificate management engine
- `ingress-nginx`: Required for HTTP-01 challenge validation
## Usage

### Basic Usage

```hcl
module "letsencrypt_issuer" {
  source = "../../../modules/helm/letsencrypt-cert-issuer"
  
  letsencrypt_email = "admin@example.com"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `letsencrypt_email` | The email address for Let's Encrypt notifications | `string` | n/a | yes |

## Outputs

This module does not provide any outputs.

## What Gets Deployed

The module deploys two ClusterIssuer resources:

### Production Issuer (`letsencrypt-production`)
- **Server**: `https://acme-v02.api.letsencrypt.org/directory`
- **Purpose**: Issues valid, trusted certificates
- **Rate Limits**: 50 certificates per domain per week
- **Usage**: Production applications

### Staging Issuer (`letsencrypt-staging`)
- **Server**: `https://acme-staging-v02.api.letsencrypt.org/directory`
- **Purpose**: Issues test certificates (not trusted by browsers)
- **Rate Limits**: Much higher limits for testing
- **Usage**: Development and testing

## Certificate Challenge Method

Both issuers use **HTTP-01 challenge** with the following configuration:

- **Challenge Type**: HTTP-01 (proves domain ownership via HTTP)
- **Ingress Class**: `nginx` (requires NGINX ingress controller)
- **Validation Path**: `/.well-known/acme-challenge/`

## Certificate Lifecycle

1. **Request**: Ingress annotation triggers certificate request
2. **Challenge**: Let's Encrypt sends HTTP-01 challenge
3. **Validation**: NGINX serves challenge response at `/.well-known/acme-challenge/`
4. **Issuance**: Let's Encrypt validates and issues certificate
5. **Storage**: Certificate stored as Kubernetes secret
6. **Renewal**: Automatic renewal 30 days before expiration

## Monitoring Certificates

### Check ClusterIssuers
```bash
kubectl get clusterissuers
kubectl describe clusterissuer letsencrypt-production
```

### Check Certificates
```bash
kubectl get certificates -A
kubectl describe certificate app-tls-prod -n default
```

### Check Certificate Requests
```bash
kubectl get certificaterequests -A
```

## Let's Encrypt Rate Limits

### Production Limits
- **50 certificates** per registered domain per week
- **5 duplicate certificates** per week
- **300 pending authorizations** per account per 3 hours

### Staging Limits
- Much higher limits for testing
- Certificates are **not trusted** by browsers
- Use for development and testing only

## Dependencies

- cert-manager deployed and running
- NGINX ingress controller with `nginx` ingress class
- Public DNS records pointing to your ingress controller
- HTTP traffic on port 80 accessible for challenge validation


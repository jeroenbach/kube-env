# Plausible Analytics Solution

This Terraform solution deploys Plausible Analytics, a privacy-focused web analytics platform, using Helm on Kubernetes. It includes persistent storage for PostgreSQL and ClickHouse databases, automatic SSL certificate provisioning, and ingress configuration.

## Features

- Deploys Plausible Analytics with official Helm chart
- Privacy-focused alternative to Google Analytics
- Persistent storage for PostgreSQL (config) and ClickHouse (analytics data)
- Automatic SSL certificate provisioning with Let's Encrypt
- NGINX ingress controller integration
- Azure Managed Disk integration with snapshot restore capability
- Configurable disk sizes for different database requirements

## Architecture

Plausible Analytics consists of:
- **Web Application**: The main Plausible interface and API
- **PostgreSQL Database**: Stores user accounts, site configurations, and settings
- **ClickHouse Database**: Stores analytics events and aggregated data
- **Persistent Volumes**: Azure Managed Disks for database persistence

## Usage

### Basic Usage

```hcl
module "plausible" {
  source = "../../solutions/plausible"
  
  subscription_id                = var.azure_subscription_id
  azure_disk_resource_group_name = data.terraform_remote_state.aks_cluster.outputs.azure_resource_group_name
  azure_disk_location           = data.terraform_remote_state.aks_cluster.outputs.azure_region
  plausible_dns                 = "analytics.example.com"
}
```
### Usage with Snapshot Restore

```hcl
module "plausible" {
  source = "../../solutions/plausible"
  
  subscription_id                    = var.azure_subscription_id
  azure_disk_resource_group_name     = data.terraform_remote_state.aks_cluster.outputs.azure_resource_group_name
  azure_disk_location               = data.terraform_remote_state.aks_cluster.outputs.azure_region
  plausible_dns                     = "analytics.example.com"
  
  # Restore from backups
  postgresql_restore_snapshot_id     = "/subscriptions/.../snapshots/postgresql-backup"
  clickhouse_restore_snapshot_id     = "/subscriptions/.../snapshots/clickhouse-backup"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `subscription_id` | The subscription ID for the Azure account | `string` | n/a | yes |
| `azure_disk_resource_group_name` | The resource group for the disk | `string` | n/a | yes |
| `azure_disk_location` | The location to restore the snapshot to | `string` | n/a | yes |
| `namespace` | The namespace to deploy Plausible into | `string` | `"plausible-analytics"` | no |
| `name` | The name to use for the Helm release | `string` | `"plausible-analytics"` | no |
| `plausible_dns` | The DNS name for the Plausible server | `string` | n/a | yes |
| `plausible_config_disk_size` | The size of the PostgreSQL config disk (GB) | `number` | `1` | no |
| `plausible_data_disk_size` | The size of the ClickHouse data disk (GB) | `number` | `8` | no |
| `postgresql_restore_snapshot_id` | PostgreSQL snapshot ID to restore from | `string` | `null` | no |
| `clickhouse_restore_snapshot_id` | ClickHouse snapshot ID to restore from | `string` | `null` | no |

### Variable Details

#### Database Disk Sizing

- **PostgreSQL (`plausible_config_disk_size`)**: 
  - Stores user accounts, site settings, and configurations
  - Small disk sufficient (1-2GB typically)
  - Growth is minimal and predictable

- **ClickHouse (`plausible_data_disk_size`)**:
  - Stores all analytics events and aggregated data  
  - Size depends on traffic volume and retention
  - Plan for growth: ~1GB per million page views

#### Snapshot Restore

- **Format**: Full Azure resource ID of the snapshot
- **Example**: `/subscriptions/12345.../resourceGroups/rg-backups/providers/Microsoft.Compute/snapshots/plausible-backup-20240101`
- **Usage**: Restore from previous backups or migrate between environments

## Outputs

This module does not provide any outputs.

## What Gets Deployed

### Kubernetes Resources

1. **Namespace**: `plausible-analytics` (or custom name)
2. **Persistent Volumes**: Azure Managed Disks for databases
3. **Persistent Volume Claims**: Links to the managed disks
4. **Helm Release**: Plausible Analytics application
5. **Ingress**: HTTPS access with automatic SSL certificates

### Azure Resources

- **Azure Managed Disk (PostgreSQL)**: Small disk for configuration data
- **Azure Managed Disk (ClickHouse)**: Larger disk for analytics data

## SSL and Ingress Configuration

The module automatically configures:

- **NGINX Ingress**: Routes traffic to Plausible application
- **Let's Encrypt Integration**: Automatic SSL certificate provisioning
- **Certificate Manager**: Uses `letsencrypt-production` cluster issuer
- **HTTPS Redirect**: Automatic HTTP to HTTPS redirection

## Post-Deployment Configuration

### Initial Setup

1. **Access Plausible**: Navigate to your configured DNS name (e.g., `https://analytics.example.com`)
2. **Create Account**: Set up your admin account through the web interface
3. **Add Website**: Configure your first website for analytics tracking
4. **Install Tracking Script**: Add the Plausible script to your website

### Website Integration

Add this script to your website's `<head>` section:

```html
<script defer data-api="https://analytics.example.com/api/event" 
        data-domain="your-website.com" 
        src="https://analytics.example.com/js/script.js"></script>
```

## Data Persistence and Backups

### Persistent Storage

- **PostgreSQL Data**: Stored on Azure Managed Disk with lifecycle protection
- **ClickHouse Data**: Stored on Azure Managed Disk with lifecycle protection
- **Backup Strategy**: Create disk snapshots for point-in-time recovery

### Creating Backups

```bash
# Create PostgreSQL snapshot
az snapshot create \
  --resource-group rg-cluster \
  --source pv-disk-plausible-analytics-postgresql-0 \
  --name plausible-postgresql-backup-$(date +%Y%m%d)

# Create ClickHouse snapshot  
az snapshot create \
  --resource-group rg-cluster \
  --source pv-disk-plausible-analytics-clickhouse-0 \
  --name plausible-clickhouse-backup-$(date +%Y%m%d)
```

## Monitoring and Troubleshooting

### Check Deployment Status
```bash
kubectl get all -n plausible-analytics
kubectl describe pod -n plausible-analytics
```

### View Application Logs
```bash
kubectl logs -n plausible-analytics deployment/plausible-analytics-plausible
```

### Database Status
```bash
kubectl logs -n plausible-analytics deployment/plausible-analytics-postgresql
kubectl logs -n plausible-analytics deployment/plausible-analytics-clickhouse
```

### Storage Status
```bash
kubectl get pv,pvc -n plausible-analytics
```

## Dependencies

- AKS cluster with appropriate permissions
- cert-manager deployed for SSL certificates
- NGINX ingress controller deployed
- Let's Encrypt cluster issuer configured (`letsencrypt-production`)
- Azure CLI authentication for disk management
- DNS records pointing to ingress controller

## Performance Considerations

### Resource Requirements

- **CPU**: Light for small sites, scales with traffic
- **Memory**: ClickHouse requires adequate RAM for query performance
- **Storage**: Plan ClickHouse disk size based on expected traffic volume

### Scaling Guidelines

- **Small Sites** (<100K views/month): Default settings sufficient
- **Medium Sites** (100K-1M views/month): Increase ClickHouse disk to 20-50GB
- **Large Sites** (>1M views/month): Consider dedicated node pools and larger disks

## Important Notes

- Plausible is privacy-focused and GDPR compliant by design
- No cookies are used for tracking website visitors
- All data is stored in your own infrastructure (not shared with third parties)
- ClickHouse disk size should be planned based on expected analytics volume
- PostgreSQL disk size grows slowly and predictably
- Automatic SSL certificate renewal handled by cert-manager
- Database backups should be scheduled regularly via Azure snapshots

## Related Modules

- `modules/azure/create-persistent-volume`: Creates the managed disks for database storage
- `modules/helm/cert-manager`: Required for SSL certificate management
- `modules/helm/ingress-nginx`: Required for ingress traffic routing
- `modules/cloudflare/dns-record`: Optional for DNS record management
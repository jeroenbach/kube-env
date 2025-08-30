# Azure Persistent Volume Module

This Terraform module creates an Azure Managed Disk and associated Kubernetes Persistent Volume (PV) and Persistent Volume Claim (PVC) for stateful applications in AKS clusters.

## Features

- Creates Azure Managed Disk with StandardSSD_LRS storage
- Optionally restores from an existing disk snapshot
- Creates Kubernetes Persistent Volume bound to the managed disk
- Creates Persistent Volume Claim for application usage
- Includes lifecycle protection to prevent accidental disk deletion

## Usage

### Basic Usage (Empty Disk)

```hcl
module "app_storage" {
  source = "../../../modules/azure/create-persistent-volume"
  
  # Azure Configuration
  azure_resource_group_name = "rg-my-cluster"
  azure_location           = "westeurope"
  
  # Disk Configuration
  disk_size_gb = 20
  
  # Kubernetes Configuration
  pv_name       = "my-app-pv"
  pvc_name      = "my-app-pvc"
  pvc_namespace = "default"
}
```

### Usage with Snapshot Restore

```hcl
module "restored_storage" {
  source = "../../../modules/azure/create-persistent-volume"
  
  # Azure Configuration
  azure_resource_group_name = "rg-my-cluster"
  azure_location           = "westeurope"
  
  # Disk Configuration
  disk_size_gb = 50
  snapshot_id  = "/subscriptions/.../snapshots/my-backup-snapshot"
  
  # Kubernetes Configuration
  pv_name       = "restored-app-pv"
  pvc_name      = "restored-app-pvc"
  pvc_namespace = "production"
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `azure_resource_group_name` | The resource group name to create the disk in | `string` | n/a | yes |
| `azure_location` | The Azure location to create the disk in | `string` | n/a | yes |
| `disk_size_gb` | The size of the persistent volume in GB | `number` | n/a | yes |
| `snapshot_id` | If provided, restore from this snapshot instead of creating empty disk | `string` | `null` | no |
| `pv_name` | The name of the Kubernetes persistent volume | `string` | n/a | yes |
| `pvc_name` | The name of the Kubernetes persistent volume claim | `string` | n/a | yes |
| `pvc_namespace` | The namespace for the persistent volume claim | `string` | n/a | yes |

## Outputs

This module does not currently provide outputs. The created resources can be referenced by their configured names.

## Important Notes

### Lifecycle Protection

The Azure Managed Disk includes `prevent_destroy = true` to prevent accidental deletion. This means:

- The disk will persist even when Terraform destroys the resource
- To actually delete the disk, you must first remove this lifecycle rule
- This protects your data from accidental loss during infrastructure changes

### Storage Class

Both PV and PVC are configured with `storage_class_name = "default"`. Ensure your AKS cluster has the default storage class configured, or modify this value to match your cluster's storage classes.

### Access Modes

The persistent volume uses `ReadWriteOnce` access mode, meaning it can only be mounted by a single pod at a time. This is suitable for most stateful applications like databases.

## Prerequisites

- AKS cluster with appropriate node pool and storage class
- Azure CLI authentication with permissions to create managed disks
- Kubernetes provider configured to connect to your AKS cluster

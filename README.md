# My Azure Kubernetes environment
This is the environment I use for my personal projects. I have both a Microsoft Partner Network and a Visual Studio Enterprise subscription, which provide Azure credits. In this repository, I configure my environment using these credits, aiming for the most cost- and performance-efficient setup possible.

In addition to Azure, I use a free Cloudflare subscription to manage my DNS. This project also uses Terraform to automatically create DNS records.

## Prerequisites
Ensure the following tools are installed on your machine:

- **Azure CLI**: Used to run az login to connect to your Azure cloud environment.
- **Terraform**: Used to run terraform apply and apply the various environment and application configurations.
- **Kubernetes Command-Line Tool (kubectl)**: Used to connect to the Kubernetes environments and execute the ./scripts.

Ensure that you have created the necessary **storage accounts** and **containers** within those storage accounts. Refer to the 'backend.tf' files for the specific names.

I'm running this project on a Mac. I haven't tested it on Windows. If you do, please ensure the path to your kube-config file is correct.

### Optional Tools
- **Helm**: If you want to query additional information about the Helm releases used in this repository.

## Getting started
If you have `pnpm` or `npm` installed, you can use the scripts from the `package.json` file. Otherwise you can use them as inspiration for the commands needed to deploy the environment.
Make sure to always run the `...:init` script first and then the `...:apply` script. 

When running `...:apply`, Terraform will ask you for the values of the needed variables. You can create a `terraform.tfvars` file in the respective environment folders with your values. This way, they're automatically provided.

In case of an error due to a timeout, just rerun the `...:apply` script.

## Directory Structure
The repository is organized into the following parts:

- **environments**: This folder contains the different clusters I run. For each environment, the Terraform state is stored in an Azure Storage account.
- **apps**: These are the various applications deployed to the clusters. Each application stores its state separately from the environments.
- **helm-charts**: Used to deploy resources directly to the clusters. These are grouped into logical Helm releases. For example, the Let's Encrypt cluster issuer is deployed via a Helm chart in this folder.
- **modules**: Contains reusable modules for the environment and application deployments. These are categorized by provider: Azure and Helm.
- **scripts**: Includes helper scripts for connecting to tools such as Rancher and Grafana.

## Cheapest Azure Kubernetes Environment
Through trial and error, I found the cheapest way to run an Azure Kubernetes environment (have a look at: `environments/aks-mpn-westeu-prod`). The costs are approximately $35 per month, primarily the price the cheapest VM you can use and a few cents for a public IP address.

The `aks-mpn-westeu-prod` configuration is optimized for cost efficiency. Here are a few considerations:

- **OS Disk Size (30GB)**: The node uses around 23GB of disk space for system data, leaving approximately 7GB for containers. While this is limited, the low-memory machines used cannot handle many containers anyway. Separate managed disks are created for container data, so it is not stored on the OS disk. Keep this in mind when using large or numerous container images.
- **OS Disk Type (Ephemeral)**: The 30GB limit corresponds to the maximum size of an ephemeral disk included in the VM price. For larger storage needs, you must switch to a "Managed" disk, which will mean additional Azure costs.
- **Basic Load Balancer**: To further reduce costs, I use a Basic Load Balancer. Note that this configuration only allows a single node pool (though you can scale the node pool to multiple nodes). Be cautious when modifying the node pool, as updates will take the environment offline.


## Certificates
To automatically generate certificates for my ingress controllers, I use the setup detailed in this guide:: https://dev.to/ileriayo/adding-free-ssltls-on-kubernetes-using-certmanager-and-letsencrypt-a1l

## Azure Resource Naming Conventions
I follow this naming convention for my Azure resources:
{resourceType}-{workload/app}-{subscription}-{environment}-{region}-{instance}

- **resourceType**: Use one of the Azure-recommended abbreviations [here](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
- **subscription**: Indicates one of my two subscriptions::
  - mpn: Microsoft Partner Network
  - vse: Visual Studio Enterprise Subscription

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-provisioning-mpn"
    storage_account_name = "stprovisioningmpn"
    container_name       = "tfstate"
    key                  = "aks-1-mpn-westeu-prod"
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

provider "helm" {
  kubernetes = {
    # Use dynamic provider configuration to use the newly created cluster directly
    host                   = module.aks_cluster.kube_config.host
    client_certificate     = base64decode(module.aks_cluster.kube_config.client_certificate)
    client_key             = base64decode(module.aks_cluster.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  # Use dynamic provider configuration to use the newly created cluster directly
  host                   = module.aks_cluster.kube_config.host
  client_certificate     = base64decode(module.aks_cluster.kube_config.client_certificate)
  client_key             = base64decode(module.aks_cluster.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks_cluster.kube_config.cluster_ca_certificate)
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token != "" ? var.cloudflare_api_token : null
}


# =============================================================================
# INPUT VARIABLES
# =============================================================================
variable "azure_subscription_id" {
  description = "The subscription ID for the Azure account."
  type        = string
}
variable "cloudflare_api_token" {
  description = "The api token for Cloudflare. If not provided we don't update the dns."
  type        = string
}
variable "cloudflare_zone_id" {
  description = "The zone ID for Cloudflare DNS. If not provided we don't update the dns."
  type        = string
}
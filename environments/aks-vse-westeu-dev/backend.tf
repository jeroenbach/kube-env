terraform {
  backend "azurerm" {
    resource_group_name  = "rg-provisioning-vse"
    storage_account_name = "stprovisioningvse"
    container_name       = "tfstate"
    key                  = "aks-vse-westeu-dev.tfstate"
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-provisioning-mpn"
    storage_account_name = "stprovisioningmpn"
    container_name       = "tfstate"
    key                  = "aks-mpn-westeu-prod.tfstate"
  }
}

#!/usr/bin/env bash
RESOURCE_GROUP="rg-provisioning-mpn"
LOCATION="westeurope"
STORAGE_ACCOUNT="stprovisioningmpn"
CONTAINER_NAME="tfstate"

az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --encryption-services blob \
  --https-only true \
  --output none

ACCOUNT_KEY=$(az storage account keys list \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[0].value" \
  -o tsv)

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --auth-mode key \
  --public-access off \
  --output none

echo "Storage account '$STORAGE_ACCOUNT' with container 'tfstate' provisioned in resource group '$RESOURCE_GROUP'."

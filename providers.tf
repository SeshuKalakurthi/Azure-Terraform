terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "0.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.23.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "f8d1356e-e5e2-4298-bf41-7e6e8fbb11e3"
  client_id       = "d2ad0d89-ce6e-4135-b43c-0c2f7d8e8874"
  client_secret   = "ggY8Q~qJqQYZ2VUBdukEyD3gyqBTDwNc2rCCnaHF"
  tenant_id       = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"

}
# Configure the Microsoft Azure Provider
provider "azapi" {

  subscription_id = "f8d1356e-e5e2-4298-bf41-7e6e8fbb11e3"
  client_id       = "d2ad0d89-ce6e-4135-b43c-0c2f7d8e8874"
  client_secret   = "ggY8Q~qJqQYZ2VUBdukEyD3gyqBTDwNc2rCCnaHF"
  tenant_id       = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
}

resource "azapi_resource" "rg" {
  type      = "Microsoft.Resources/resourceGroups@2021-04-01"
  name      = var.rgname
  location  = var.location
  parent_id = "/subscriptions/f8d1356e-e5e2-4298-bf41-7e6e8fbb11e3"
}
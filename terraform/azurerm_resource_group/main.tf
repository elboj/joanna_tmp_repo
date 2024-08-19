terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.113.0"
    }
  }
  backend "azurerm" {
    
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

#Create a new resource group
resource "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
  location = var.location
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.location
}
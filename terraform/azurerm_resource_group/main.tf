
#Create a new resource group
resource "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
  location = var.location
}

output "resource_group_name" {
  value = azurerm_resource_group.resource_group.location
}
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.113.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "rg-uks-gen-dev001"  
    storage_account_name = "sauksapimdev001"                     
    container_name       = "terraform"                      
    key                  = "cmp.terraform.tfstate"
    client_id            = "b23745d5-3e75-4c00-a6a1-d476e9f4b7b2"
    client_secret        = "Zb.8Q~QUlEVrAg2GswkcTATYFr0P9AKH7vhdLbp1"
    subscription_id      = "4d2f3d90-3f7a-4f44-bb7f-bee999a3638b"
    tenant_id            = "5e9800ce-6304-48bc-9716-d6d12b2353eb"

  }
}



provider "azurerm" {
  # Configuration options
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

module "azurerm_resource_group" {
  source = "./terraform/azurerm_resource_group"
  location = "uksouth"
  resource_group_name = "cloud-migration-terraform"
}

module "azurerm_vnet" {
  source = "./terraform/azurerm_vnet"
  virtual_network_name = "cmt-poc-vnt-uks"
  resource_group_name = module.azurerm_resource_group.resource_group_name
  location = "uksouth"
  address_space = "172.19.0.0/16"
  # depends_on = [ module.azurerm_resource_group ]
}

module "azurerm_appgw_subnet" {
  source = "./terraform/azurerm_subnet"
  virtual_network_name = module.azurerm_vnet.virtual_network_name
  resource_group_name = module.azurerm_resource_group.resource_group_name
  address_prefixes = ["172.19.0.0/24"]
  subnet_name = "appgwaf_snt_cmt_poc001"
  # depends_on = [ module.azurerm_vnet ]
}

module "azurerm_db_subnet" {
  source = "./terraform/azurerm_subnet"
  virtual_network_name = module.azurerm_vnet.virtual_network_name
  resource_group_name = module.azurerm_resource_group.resource_group_name
  address_prefixes = ["172.19.2.0/24"]
  subnet_name = "db_snt_cmt_poc001"
  # depends_on = [ module.azurerm_vnet ]
}

module "azurerm_web_subnet" {
  source = "./terraform/azurerm_subnet"
  virtual_network_name = module.azurerm_vnet.virtual_network_name
  resource_group_name = module.azurerm_resource_group.resource_group_name
  address_prefixes = ["172.19.1.0/24"]
  subnet_name = "web_snt_cmt_poc001"
  # depends_on = [ module.azurerm_vnet ]
}

module "azurerm_appgw" {
  source = "./terraform/azurerm_app_gateway"
  virtual_network_name = module.azurerm_vnet.virtual_network_name
  resource_group_name = module.azurerm_resource_group.resource_group_name
  appgw_subnet_name = "appgwaf_snt_cmt_poc001"
  appgw_public_ip = "appgw_pip"
  domain_name_label = "cmppip"
  app_gateway_name = "cmpappgwuks"
  sku_name = "Standard_v2"
  sku_tier = "Standard_v2"
  appgw_congif_pip = "cmp-ip-configuration"
  frontend_ip_configuration_name = "ip-config"
  backend_address_pool_name = "cmp-bep"
  http_setting_name = "cmp_http"
  listener_name = "cmp_listener"
  frontend_port_name = "cmp-port"
  request_routing_rule_name = "cmp-rule"
  subnet_id = module.azurerm_appgw_subnet.subnet_id

}

module "azurerm_vmss" {
  source = "./terraform/azurerm_vmss"
  resource_group_name = module.azurerm_resource_group.resource_group_name
  location = "uksouth"
  virtual_network_name = module.azurerm_vnet.virtual_network_name
  vmss_subnet_name = "web_snt_cmt_poc001"
  vmss_name = "ukspocvmss"
  vmss_sku = "Standard_F2"
  rsv_name = "rsv-cmp-poc"
  subnet_id = module.azurerm_web_subnet.subnet_id
  # depends_on = [ module.azurerm_web_subnet ]
}

module "azurerm_key_vault" {
  source = "./terraform/azurerm_keyvault"
  kv_name = "kvcmppoc"
  sub_resource_name = "vault"
  private_dns_name = "privatelink.vaultcore.azure.net"
  private_endpoint_subnet_name = "db_snt_cmt_poc001"
  resource_group_name = module.azurerm_resource_group.resource_group_name
  location = "uksouth"
  virtual_network_name = module.azurerm_vnet.virtual_network_name
}

module "azurerm_sql" {
  source = "./terraform/azurerm_mssql_server"
  resource_group_name = module.azurerm_resource_group.resource_group_name
  location = "uksouth"
  mssql_server_name = "cmpftpoc-server"
  administrator_login = "joanna"
  administrator_login_password = "j$#oaJUTna23_45$"
  mssql_database_name = "cmp-db-poc"
  max_size_gb = 30
  min_capacity = 1
  private_endpoint_subnet_name = module.azurerm_db_subnet.subnet_name
  virtual_network_name = module.azurerm_vnet.virtual_network_name
}

module "azurerm_storage_account" {
  source = "./terraform/azurerm_storage_account"
  resource_group_name = module.azurerm_resource_group.resource_group_name
  location = "uksouth"
  account_replication_type = "LRS"
  account_tier = "Standard"
  storage_account_name = "saukspoccmptf"
}

module "azurerm_cosmosdb_account" {
  source = "./terraform/azurerm_cosmos_db"
  resource_group_name = module.azurerm_resource_group.resource_group_name
  location = "uksouth"
  offer_type = "Standard"
  kind = "MongoDB"
  cosmos_db_name = "cmp-cosmos-mongo-db"
}


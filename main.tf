module "azurerm_resource_group" {
  source = "./terraform/azurerm_resource_group"
  location = "uksouth"
  resource_group_name = "cloud-migration-terraform"
}

module "azurerm_vnet" {
  source = "./terraform/azurerm_vnet"
  virtual_network_name = "cmt-poc-vnt-uks"
  resource_group_name = "cloud-migration-terraform"
  location = "uksouth"
  address_space = "172.19.0.0/16"
  depends_on = [ module.azurerm_resource_group ]
}

module "azurerm_appgw_subnet" {
  source = "./terraform/azurerm_subnet"
  virtual_network_name = "cmt-poc-vnt-uks"
  resource_group_name = "cloud-migration-terraform"
  address_prefixes = ["172.19.0.0/24"]
  subnet_name = "appgwaf_snt_cmt_poc001"
  depends_on = [ module.azurerm_vnet ]
}

module "azurerm_db_subnet" {
  source = "./terraform/azurerm_subnet"
  virtual_network_name = "cmt-poc-vnt-uks"
  resource_group_name = "cloud-migration-terraform"
  address_prefixes = ["172.19.2.0/24"]
  subnet_name = "db_snt_cmt_poc001"
  depends_on = [ module.azurerm_vnet ]
}

module "azurerm_web_subnet" {
  source = "./terraform/azurerm_subnet"
  virtual_network_name = "cmt-poc-vnt-uks"
  resource_group_name = "cloud-migration-terraform"
  address_prefixes = ["172.19.1.0/24"]
  subnet_name = "web_snt_cmt_poc001"
  depends_on = [ module.azurerm_vnet ]
}

module "azurerm_appgw" {
  source = "./terraform/azurerm_app_gateway"
  virtual_network_name = "cmt-poc-vnt-uks"
  resource_group_name = "cloud-migration-terraform"
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
  depends_on = [ module.azurerm_appgw_subnet ]

}

module "azurerm_vmss" {
  source = "./terraform/azurerm_vmss"
  resource_group_name = "cloud-migration-terraform"
  location = "uksouth"
  virtual_network_name = "cmt-poc-vnt-uks"
  vmss_subnet_name = "web_snt_cmt_poc001"
  vmss_name = "ukspocvmss"
  vmss_sku = "Standard_F2"
  rsv_name = "rsv-cmp-poc"
  depends_on = [ module.azurerm_web_subnet ]
}

module "azurerm_key_vault" {
  source = "./terraform/azurerm_keyvault"
  kv_name = "kvcmppoc"
  sub_resource_name = "vault"
  private_dns_name = "privatelink.vaultcore.azure.net"
  private_endpoint_subnet_name = "db_snt_cmt_poc001"
  resource_group_name = "cloud-migration-terraform"
  location = "uksouth"
  virtual_network_name = "cmt-poc-vnt-uks"
}

module "azurerm_sql" {
  source = "./terraform/azurerm_mssql_server"
  resource_group_name = "cloud-migration-terraform"
  location = "uksouth"
  mssql_server_name = "cmpftpoc-server"
  administrator_login = "joanna"
  administrator_login_password = "j$#oaJUTna23_45$"
  mssql_database_name = "cmp-db-poc"
  max_size_gb = 30
  min_capacity = 1
  private_endpoint_subnet_name = "db_snt_cmt_poc001"
  virtual_network_name = "cmt-poc-vnt-uks"
}

module "azurerm_storage_account" {
  source = "./terraform/azurerm_storage_account"
  resource_group_name = "cloud-migration-terraform"
  location = "uksouth"
  account_replication_type = "LRS"
  account_tier = "Standard"
  storage_account_name = "saukspoccmptf"
}

module "azurerm_cosmosdb_account" {
  source = "./terraform/azurerm_cosmos_db"
  resource_group_name = "cloud-migration-terraform"
  location = "uksouth"
  offer_type = "Standard"
  kind = "MongoDB"
  cosmos_db_name = "cmp-cosmos-mongo-db"
}


locals {
  server_name = format("%s-%s-%s-%s-%s", var.enterprise_name, var.environment, var.sql_db_name, var.application_name, "use-sql")
}

## RANDOMLY GENERATE SQL ADMIN PASSWORD
resource "random_password" "sql_pwd" {
  length           = 30
  special          = true
  override_special = "_%@#*&^"
}

## GET THE USERS CURRENT IP ADDRESS
data "http" "current_user_public_ip" {
  url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}

##############################################################################################################
# AZURE SQL SERVER AND DATABASE
##############################################################################################################

## DEFINE AZURE SQL SERVER DETAILS
resource "azurerm_mssql_server" "sqlserver" {
  name                         = local.server_name
  resource_group_name          = data.azurerm_resource_group.primary_rg.name
  location                     = data.azurerm_resource_group.primary_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_name
  administrator_login_password = random_password.sql_pwd.result
  minimum_tls_version          = "1.2"
  tags                         = data.azurerm_resource_group.primary_rg.tags

  azuread_administrator {
    login_username = var.sql_admin_email
    object_id      = data.azurerm_client_config.current.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }
}

## DEFINE AZURE SQL DATABASE
resource "azurerm_mssql_database" "sqldb" {
  name                        = var.sql_db_name
  server_id                   = azurerm_mssql_server.sqlserver.id
  collation                   = "SQL_Latin1_General_CP1_CI_AS"
  auto_pause_delay_in_minutes = var.sql_db_auto_pause
  max_size_gb                 = var.sql_max_db_size
  min_capacity                = var.sql_min_capacity
  read_replica_count          = 0
  read_scale                  = false
  sku_name                    = var.sql_sku
  zone_redundant              = false
  tags                        = data.azurerm_resource_group.primary_rg.tags
}

## DEFINE FIREWALL RULE - ALLOW AZURE RESOURCES
resource "azurerm_mssql_firewall_rule" "allowazureresources" {
  name                = "AllowAzureResourcesAccess"
  server_id           = azurerm_mssql_server.sqlserver.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

## DEFINE FIREWALL RULE - ALLOW AZURE RESOURCES
resource "azurerm_mssql_firewall_rule" "sql_firewall_rule" {
  name                = "ClientIP-ProvisioningUser"
  server_id           = azurerm_mssql_server.sqlserver.id
  start_ip_address    = chomp(data.http.myip.response_body)
  end_ip_address      = chomp(data.http.myip.response_body)
}

##############################################################################################################
# SET SQL KEY VAULT SECRETS
##############################################################################################################

# SET KEY VAULT SECRET FOR ADMIN USERNAME
resource "azurerm_key_vault_secret" "sql_user" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-azure-sql-admin-user"
  value        = var.sql_admin_name
}

# SET KEY VAULT SECRET FOR ADMIN PASSWORD
resource "azurerm_key_vault_secret" "sql_pwd" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-azure-sql-admin-pwd"
  value        = random_password.sql_pwd.result
}

# SET KEY VAULT SECRET FOR STANDARD DATABASE CONNECTION STRING
resource "azurerm_key_vault_secret" "sql_connect_string" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-metadata-db-connection-string"
  value        = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sqldb.name};Persist Security Info=False;User ID=${var.sql_admin_name};Password=${random_password.sql_pwd.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
}

# SET KEY VAULT SECRET FOR JDBC DATABASE CONNECTION STRING
resource "azurerm_key_vault_secret" "sql_connect_string_jdbc" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-metadata-db-jdbc-connection-string"
  value        = "jdbc:sqlserver://${azurerm_mssql_server.sqlserver.fully_qualified_domain_name}:1433;databasename=${azurerm_mssql_database.sqldb.name};user=${var.sql_admin_name};password=${random_password.sql_pwd.result};driver=com.microsoft.sqlserver.jdbc.SQLServerDriver"
}

# SET KEY VAULT SECRET FOR ODBC DATABASE CONNECTION STRING
resource "azurerm_key_vault_secret" "sql_connect_string_odbc" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-metadata-db-odbc-connection-string"
  value        = "DRIVER={ODBC Driver 17 for SQL Server};SERVER=${azurerm_mssql_server.sqlserver.fully_qualified_domain_name};DATABASE=${azurerm_mssql_database.sqldb.name};UID=${var.sql_admin_name};PWD=${random_password.sql_pwd.result}"
}

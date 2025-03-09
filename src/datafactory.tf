locals {
  df_name = format("%s-%s-%s-%s", var.enterprise_name, var.environment, var.application_name, "use-adf")
}

resource "azurerm_data_factory" "adf" {
  name                = local.df_name
  resource_group_name = data.azurerm_resource_group.primary_rg.name
  location            = data.azurerm_resource_group.primary_rg.location
  tags                = data.azurerm_resource_group.primary_rg.tags

  identity {
    type = "SystemAssigned"
  }
}

## KV Access Policies
resource "azurerm_key_vault_access_policy" "dfspn" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.adf.identity[0].principal_id

  key_permissions = [
    "Get", "List"
  ]

  secret_permissions = [
    "Get", "List"
  ]
}

## ADD ADF MANAGED IDENTITY TO DATALAKE AS STORAGE BLOB DATA CONTRIBUTOR
resource "azurerm_role_assignment" "dfdl" {
  scope                            = azurerm_storage_account.datalake.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_data_factory.adf.identity[0].principal_id
  skip_service_principal_aad_check = true
}

## ADD ADF MANAGED IDENTITY TO DATABRICKS AS CONTRIBUTOR
resource "azurerm_role_assignment" "dfd2" {
  scope                            = azurerm_databricks_workspace.dbw.id
  role_definition_name             = "Contributor"
  principal_id                     = azurerm_data_factory.adf.identity[0].principal_id
  skip_service_principal_aad_check = true
}

##############################################################################################################
# SET KEY VAULT SECRETS
##############################################################################################################

# SET KEY VAULT SECRET FOR RESOURCE ID
resource "azurerm_key_vault_secret" "df-id" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-datafactory-resource-id"
  value        = azurerm_data_factory.adf.id
}

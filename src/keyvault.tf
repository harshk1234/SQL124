locals {
  kv_name = format("%s-%s-%s-%s", var.enterprise_name, var.environment, var.application_name, "use-kv")
}

resource "azurerm_key_vault" "kv" {
  name                        = local.kv_name
  resource_group_name         = data.azurerm_resource_group.primary_rg.name
  location                    = data.azurerm_resource_group.primary_rg.location
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = var.tags

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
  ]

  key_permissions = [
    "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
  ]

  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]

  storage_permissions = [
    "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "SetSAS", "Update"
  ]
}

# KV Access Policies
resource "azurerm_key_vault_access_policy" "kvusers" {
  depends_on = [azurerm_key_vault_access_policy.current_user]

  for_each = data.azuread_user.users

  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions = [
    "Get", "List"
  ]

  secret_permissions = [
    "Get", "List"
  ]
}

# ENTER IN PLACEHOLDER SECRETS IN THE VARIABLES.TF FILE AND THEN UNCOMMENT THIS BLOCK TO CREATE PLACEHOLDER SECRETS
resource "azurerm_key_vault_secret" "secrets" {
  depends_on = [azurerm_key_vault_access_policy.current_user]

  for_each = toset(var.key_vault_secrets)

  key_vault_id = azurerm_key_vault.kv.id
  name         = each.value
  value        = "placeholder"
}

##############################################################################################################
# SET TENANT AND SUBSCRIPTION ID SECRETS
##############################################################################################################

## SECRET - TENANT ID
resource "azurerm_key_vault_secret" "tenant_secret" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
}

## SECRET - SUBSCRIPTION ID
resource "azurerm_key_vault_secret" "subscription_secret" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-subscription-id"
  value        = data.azurerm_client_config.current.subscription_id
}

## SECRET - SERVICE PRINCIPAL ID
# resource "azurerm_key_vault_secret" "service_principal" {
#   depends_on   = [azurerm_key_vault_access_policy.current_user]
#   key_vault_id = azurerm_key_vault.kv.id
#   name         = "sec-svp-id"
#   value        = var.servicePrincipalId
# }

##############################################################################################################
# SET RESOURCE ID KEY VAULT SECRET
##############################################################################################################

# SET KEY VAULT SECRET FOR RESOURCE ID
resource "azurerm_key_vault_secret" "kv" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-key-vault-resource-id"
  value        = azurerm_key_vault.kv.id
}

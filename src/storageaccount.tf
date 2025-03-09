locals {
  storage_account_name = format("%s%s%s%s", "bwcoent", var.environment, var.application_name, "usedls")
}

resource "azurerm_storage_account" "datalake" {
  depends_on                      = [azurerm_key_vault.kv]
  name                            = local.storage_account_name
  resource_group_name             = data.azurerm_resource_group.primary_rg.name
  location                        = data.azurerm_resource_group.primary_rg.location
  account_kind                    = var.storage_account_kind
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  is_hns_enabled                  = true
  allow_nested_items_to_be_public = true
  min_tls_version                 = "TLS1_2"
  tags                            = var.tags
}

resource "azurerm_storage_container" "strgconatainers" {
  for_each              = toset(var.storage_account_containers)
  name                  = each.key
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
}

locals {
  primary_rg_name   = "BWCO-ENT-PROD-EDH"
  # secondary_rg_name = format("%s-%s-%s-%s", "rg", var.rg_name, var.secondary_rg_location, var.environment)
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "primary_rg" {
  # depends_on = [azurerm_resource_group.create_primary]
  name       = local.primary_rg_name
}

# data "azurerm_resource_group" "secondary_rg" {
#   depends_on = [azurerm_resource_group.create_secondary]
#   name       = local.secondary_name
# }

data "azuread_user" "users" {
  for_each = toset(var.key_vault_access_policy_devs)

  user_principal_name = each.value
}

# GET THE USERS CURRENT IP ADDRESS
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
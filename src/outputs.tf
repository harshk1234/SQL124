output "keyvault_url" {
  value = azurerm_key_vault.kv.vault_uri
}

# output "sqlserver_fqdn" {
#   value = azurerm_mssql_server.sqlserver.fully_qualified_domain_name
# }

# output "datalake_url" {
#   value = azurerm_storage_account.datalake.primary_dfs_endpoint
# }

output "current_ip_address" {
  value = chomp(data.http.myip.response_body)
}
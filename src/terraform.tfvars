#define application name
application_name      = "edh"
enterprise_name       = "bwco-ent"
primary_rg_location   = "eastus"
environment           = "prod"

# define tags
tags = {
  Environment = "prod",
  Application = "edh",
  Division    = "ENT",
  Platform    = "BWCO"
}

#key-vault
# servicePrincipalId = "a5b15d5e-91d8-4386-ad25-c34e27591da6"

key_vault_access_policy_devs = [
]

certificate_permissions = [
  "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"
]

key_permissions = [
  "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
]

secret_permissions = [
  "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
]

storage_permissions = [
  "Backup", "Delete", "DeleteSAS", "Get", "GetSAS", "List", "ListSAS", "Purge", "Recover", "RegenerateKey", "Restore", "Set", "setSAS", "Update"
]

# storage
storage_account_containers = ["raw", "prodcatalog"]

#sql
sql_admin_name = "sqlAdminUser"
sql_admin_email = "ted.tasker@insight.com"

# databricks
# databricks cluster variables
cluster1_name                = "DataEngineeringCluster"
cluster1_spark_version       = "13.3.x-scala2.12"
cluster1_min_workers         = 2
cluster1_max_workers         = 8
cluster1_number_of_workers   = 2
cluster1_node_type_id        = "Standard_D16ads_v5"
cluster1_driver_node_type_id = "Standard_D16ads_v5"
cluster1_auto_terminate      = 60
cluster_data_security_mode   = "USER_ISOLATION"

# databricks sql warehouse variables
sql_warehouse_max_num_clusters = 1
sql_warehouse_cluster_size     = "Small"
sql_warehouse_auto_stop_mins   = 30
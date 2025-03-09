locals {
  dbk_name                  = format("%s-%s-%s-%s", var.enterprise_name, var.environment, var.application_name, "use-dbw")
  dbk_managed_rg_name       = format("%s-%s-%s-%s-%s", var.enterprise_name, var.environment, var.application_name, "databricks", "use-rg")
  # dbk_access_connector_name = format("%s-%s-%s-%s-%s", "mi", "databricks", var.application_name, var.environment, var.sdt_suffix)
  sql_warehouse_name        = format("%s-%s-%s", "sql-warehouse", var.application_name, var.environment)
}

resource "azurerm_databricks_workspace" "dbw" {
  name                        = local.dbk_name
  resource_group_name         = data.azurerm_resource_group.primary_rg.name
  location                    = data.azurerm_resource_group.primary_rg.location
  sku                         = var.databrick_sku
  managed_resource_group_name = local.dbk_managed_rg_name
  tags                        = var.tags
}


## DATABRICKS CLUSTER
resource "databricks_cluster" "cluster1" {
  depends_on              = [azurerm_databricks_workspace.dbw]
  cluster_name            = var.cluster1_name
  spark_version           = var.cluster1_spark_version
  node_type_id            = var.cluster1_node_type_id
  driver_node_type_id     = var.cluster1_driver_node_type_id
  data_security_mode      = var.cluster_data_security_mode
  autotermination_minutes = var.cluster1_auto_terminate

  autoscale {
    min_workers = var.cluster1_min_workers
    max_workers = var.cluster1_max_workers
  }

  spark_conf = {
    "spark.databricks.io.cache.enabled" : true
    "spark.databricks.delta.preview.enabled" : true
    "spark.sql.autoBroadcastJoinThreshold" : -1
    "spark.driver.maxResultSize" : "8g"
    "spark.databricks.sql.initial.catalog.name" : var.environment
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" : true
    "spark.databricks.delta.autoCompact.enabled" : true
  }

  dynamic "library" {
    for_each = var.cluster1_py_libraries
    content {
      pypi {
        package = library.value
      }
    }
  }

  spark_env_vars = {
    "PYSPARK_PYTHON" : "/databricks/python3/bin/python3"
  }

  custom_tags = var.tags

  lifecycle {
    ignore_changes = [custom_tags]
  }
}

locals {
  dbw_url = "https://${azurerm_databricks_workspace.dbw.workspace_url}"
}

## DATABRICKS SQL WAREHOUSE 
resource "databricks_sql_endpoint" "sql_warehouse" {
  depends_on                = [azurerm_databricks_workspace.dbw]
  name                      = local.sql_warehouse_name
  cluster_size              = var.sql_warehouse_cluster_size
  max_num_clusters          = var.sql_warehouse_max_num_clusters
  auto_stop_mins            = var.sql_warehouse_auto_stop_mins
  enable_photon             = false
  enable_serverless_compute = true
}

## DATABRICKS ACCESS CONNECTOR
# resource "azapi_resource" "access_connector" {
#   type      = "Microsoft.Databricks/accessConnectors@2022-04-01-preview"
#   name      = local.dbk_access_connector_name
#   location  = data.azurerm_resource_group.primary_rg.location
#   parent_id = data.azurerm_resource_group.primary_rg.id

#   identity {
#     type = "SystemAssigned"
#   }

#   body = jsonencode({ properties = {} })
# }

## DATABRICKS ROLE ASSIGNMENT ON DATALAKE
# resource "azurerm_role_assignment" "example" {
#   scope                = azurerm_storage_account.datalake.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azapi_resource.access_connector.identity[0].principal_id
# }

## DATABRICKS PAT TOKEN
## Currently you cannot write to key vault with a service principal.
## Uncomment the code block below to create a secret scope when authenticating via azure cli (local development)

# resource "null_resource" "databricks_pat" {
#     depends_on = [
#         azurerm_key_vault_access_policy.current_user,
#         azurerm_databricks_workspace.dbw,
#         local.dbw_url
#     ]

#     triggers  =  { always_run = timestamp() }

#     provisioner "local-exec" {
#         command = ".\\generate-pat-token.sh"

#         environment = {
#             RESOURCE_GROUP = var.rg_name
#             DATABRICKS_WORKSPACE_RESOURCE_ID = azurerm_databricks_workspace.dbw.id
#             KEY_VAULT = azurerm_key_vault.kv.name
#             SECRET_NAME = "sec-databricks-access-token"
#             DATABRICKS_ENDPOINT = local.dbw_url
#             # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID are already
#             # present in the environment if you are using the Terraform
#             # extension for Azure DevOps or the starter from
#             # https://github.com/algattik/terraform-azure-pipelines-starter.
#             # Otherwise, provide them as additional variables.
#         }
#     }
# }


## Currently you cannot create a secret scope while authenticating with a service principal
## Uncomment the code block below to create a secret scope when authenticating via azure cli (local development)

#resource "databricks_secret_scope" "kv" {
#    depends_on = [
#        azurerm_databricks_workspace.dbw,
#        azurerm_key_vault.kv,
#        null_resource.databricks_pat
#    ]

#    name = var.databricks_secret_scope

#    keyvault_metadata {
#        resource_id = azurerm_key_vault.kv.id
#        dns_name = azurerm_key_vault.kv.vault_uri
#    }
#}


##############################################################################################################
# SET KEY VAULT SECRETS
##############################################################################################################

# SET KEY VAULT SECRET FOR RESOURCE ID
resource "azurerm_key_vault_secret" "dbw-id" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-databricks-resource-id"
  value        = azurerm_databricks_workspace.dbw.id
}

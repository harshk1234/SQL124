# variable "rg_name" {
#   type = string
# }

variable "enterprise_name" {
  type = string
}

variable "primary_rg_location" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["poc", "dev", "test", "prod"], var.environment)
    error_message = "Valid value is one of the following: poc, dev, test, prod."
  }
}

variable "tags" {
  description = "Tags to set for all resources"
  type        = map(string)
}

variable "should_create_rg" {
  type    = number
  default = 1
}

variable "key_vault_access_policy_devs" {
  type = list(string)
}

variable "certificate_permissions" {
  type = list(string)
}

variable "key_permissions" {
  type = list(string)
}

variable "secret_permissions" {
  type = list(string)
}

variable "application_name" {
  type = string
}

variable "sdt_suffix" {
  type    = string
  default = "sdt"
}

variable "storage_permissions" {
  type = list(string)
}

variable "key_vault_secrets" {
  type = list(string)
  default = [
    "sec-svp-secret"
  ]
}

# variable "servicePrincipalId" {
#   type = string
# }

variable "logic_app_email_notify_name" {
  type    = string
  default = "email-notify"
}

variable "storage_account_name" {
  type    = string
  default = "dls"
}

variable "storage_account_kind" {
  type    = string
  default = "StorageV2"
}

variable "storage_account_tier" {
  type    = string
  default = "Standard"
}

variable "storage_account_replication_type" {
  type    = string
  default = "GRS"
}

variable "storage_account_containers" {
  type    = list(string)
  default = ["dropzone", "raw"]
}

variable "sql_db_name" {
  type    = string
  default = "metadata"
}

variable "sql_db_auto_pause" {
  type    = number
  default = 60
}

variable "sql_max_db_size" {
  type    = number
  default = 200
}

variable "sql_min_capacity" {
  type    = number
  default = 1.25
}

variable "sql_sku" {
  type    = string
  default = "GP_S_Gen5_4"
}

variable "sql_admin_name" {
  type    = string
  default = "sqlAdminUser"
}

variable "sql_admin_email" {
  type = string
}

variable "cluster1_name" {
  type    = string
  default = "DataEngineeringCluster"
}

variable "cluster1_spark_version" {
  type    = string
  default = "13.3.x-scala2.12"
}

variable "cluster1_node_type_id" {
  type = string
}

variable "cluster1_driver_node_type_id" {
  type = string
}

variable "cluster1_auto_terminate" {
  type = number
}

variable "cluster1_min_workers" {
  type = number
}

variable "cluster1_max_workers" {
  type = number
}

variable "cluster1_number_of_workers" {
  type = number
}

variable "cluster1_py_libraries" {
  type    = list(string)
  default = ["xlrd==1.2.0", "openpyxl", "azure-mgmt-datafactory", "azure-mgmt-resource", "azure-identity", "sparkaid"]
}

variable "cluster_data_security_mode" {
  type    = string
  default = "USER_ISOLATION"
}

variable "sql_warehouse_max_num_clusters" {
  type = number
}

variable "sql_warehouse_auto_stop_mins" {
  type = number
}

variable "sql_warehouse_cluster_size" {
  type    = string
  default = "Small"
}

variable "databrick_sku" {
  type    = string
  default = "premium"
}
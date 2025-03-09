terraform {
  required_version = ">= 1.4.2"

  required_providers {
    azurerm = {
      version = ">=3.0.0"
    }

    databricks = {
      source = "databricks/databricks"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.dbw.id
  host                        = azurerm_databricks_workspace.dbw.workspace_url
}
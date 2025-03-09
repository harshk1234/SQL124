# terraform {
#   # Backend variables are initialized by Azure DevOps
#   backend "azurerm" {
#     resource_group_name  = "LENS_ttaskerNov23"
#     storage_account_name = "terraforminstall"
#     container_name       = "install"
#     key                  = "dev/tfstate/terraform.tfstate"
#   }
# }
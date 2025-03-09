locals {
  la_email_notify_name = format("%s-%s-%s-%s", var.enterprise_name, var.environment, var.application_name, "use-logic")
}

resource "azurerm_logic_app_workflow" "email_notify_lawf" {
  name                = local.la_email_notify_name
  resource_group_name = data.azurerm_resource_group.primary_rg.name
  location            = data.azurerm_resource_group.primary_rg.location
  tags                = var.tags
}

resource "azurerm_logic_app_trigger_http_request" "email_notify_http" {
  name         = "http-post-trigger"
  logic_app_id = azurerm_logic_app_workflow.email_notify_lawf.id

  schema = <<SCHEMA
    {
        "properties": {
            "Color": {
                "type": "string"
            },
            "DataFactoryName": {
                "type": "string"
            },
            "EmailTo": {
                "type": "string"
            },
            "Importance": {
                "type": "string"
            },
            "Message": {
                "type": "string"
            },
            "PipelineName": {
                "type": "string"
            },
            "PipelineRunID": {
                "type": "string"
            },
            "Subject": {
                "type": "string"
            }
        },
        "type": "object"
    }
    SCHEMA
}

resource "azurerm_logic_app_action_custom" "email_notify_init" {
  name         = "initialize-variables"
  logic_app_id = azurerm_logic_app_workflow.email_notify_lawf.id

  body = <<BODY
    {
        "description": "A variable to configure the auto expiration age in days. Configured in negative number. Default is -30 (30 days old).",
        "inputs": {
            "variables": [
                {
                    "name": "Email Body",
                    "type": "string",
                    "value": "<hr/>\nDataFactoryName: <b>@{triggerBody()?['DataFactoryName']}</b><br/>\nPipelineName: <b>@{triggerBody()?['PipelineName']}</b><br/>\nPipelineRunID: <b>@{triggerBody()?['PipelineRunID']}</b><br/>\n<p style='color:@{triggerBody()?['Color']}'>Message: @{triggerBody()?['Message']}</p>\n<hr/>\n<p style='color:Gray'> Please don't reply to this auto generated notification e-mail. Contact us if you have any questions. </p>"
                }
            ]
        },
        "runAfter": {},
        "type": "InitializeVariable"
    }
    BODY
}

resource "azurerm_logic_app_action_custom" "email_notify_send" {
  depends_on   = [azurerm_logic_app_action_custom.email_notify_init]
  name         = "send-email"
  logic_app_id = azurerm_logic_app_workflow.email_notify_lawf.id

  body = <<BODY
    {
        "description": "A variable to configure the auto expiration age in days. Configured in negative number. Default is -30 (30 days old).",
        "inputs": {
            "host": {
                "connection": {
                "name": "@parameters('$connections')['office365_1']['connectionId']"
                }
            },
            "method": "post",
            "body": {
                "Body": "<p><br>\n@{variables('Email Body')}<br>\n</p>",
                "Subject": "@triggerBody()?['Subject']",
                "To": "@triggerBody()?['EmailTo']",
                "Importance": "@triggerBody()?['Importance']"
            },
            "path": "/v2/Mail"
        },
        "runAfter": {
            "initialize-variables": [ "Succeeded" ]
        },
        "type": "ApiConnection"
    }
    BODY
}

# SET KEY VAULT SECRET FOR HTTO REQUEST URL
resource "azurerm_key_vault_secret" "email_notify_http" {
  depends_on   = [azurerm_key_vault_access_policy.current_user]
  key_vault_id = azurerm_key_vault.kv.id
  name         = "sec-logic-app-email-notification-http-url"
  value        = azurerm_logic_app_trigger_http_request.email_notify_http.callback_url
}

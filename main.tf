/*resource "azapi_resource" "storageacc" {
  type      = "Microsoft.Storage/storageAccounts@2022-05-01"
  name      = "${var.storageaccname}1"
  location  = var.location
  parent_id = azapi_resource.rg.id
  body = jsonencode({
    sku = {
      name = "${var.storageacctype}"
    }
    kind = "${var.storageacckind}"
    properties = {

      encryption = {
        services = {
          blob = {
            enabled = true
          }
          file = {
            enabled = true
          }
        }
      }
      supportsHttpsTrafficOnly = true
      allowBlobPublicAccess    = true
    }
  })
}*/

// ~~~~~~~~~~~~~~~~~~ STORAGE ACCOUNT ~~~~~~~~~~~~~~~~~~~~

resource "azurerm_storage_account" "storageacc" {
  name                             = var.storageaccname
  resource_group_name              = azurerm_resource_group.rg.name
  location                         = var.location
  account_tier                     = "Standard"
  account_kind                     = var.storageacckind
  account_replication_type         = "LRS"
  cross_tenant_replication_enabled = "false"
}

// ~~~~~~~~~~~~~~~~~ SERVICEBUS NAMESPACE ~~~~~~~~~~~~~~~~~~~~

resource "azurerm_servicebus_namespace" "servicebus" {
  name                = var.servicebusname
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  capacity            = "0"
}

// ~~~~~~~~~~~~~~~~~~~ ADD SERVICEBUS QUEUE ~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_servicebus_queue" "queue1" {
  name                                    = "terraformqueue1"
  namespace_id                            = azurerm_servicebus_namespace.servicebus.id
  lock_duration                           = "PT30S"
  max_size_in_megabytes                   = "5120"
  default_message_ttl                     = "P14D"
  duplicate_detection_history_time_window = "PT30S"
  max_delivery_count                      = "10"
  status                                  = "Active"
  auto_delete_on_idle                     = "P10675199DT2H48M5.4775807S"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~ APP SERVICE PLAN ~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_service_plan" "plan1" {
  name                = "terraform-win-app-plan"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "S1"
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ APP SERVICE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_app_service" "app1" {
  name                = var.functionappname
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_service_plan.plan1.id
  identity {
    type = "SystemAssigned"
  }
  client_affinity_enabled = false
  site_config {
    always_on                 = true
    min_tls_version           = "1.2"
    use_32_bit_worker_process = false
  }
  app_settings = {
    "AzureWebJobsDashboard"          = azurerm_storage_account.storageacc.primary_connection_string
    "AzureWebJobsStorage"            = azurerm_storage_account.storageacc.primary_connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.insights1.connection_string

    "storage" = "${azurerm_key_vault_secret.storageaccountkey.value}"

  }
}

# ~~~~~~~~~~~~~~~~~~~~~~ APPLICATION INSIGHTS ~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_application_insights" "insights1" {
  name                = "terraform-function-appinsights"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  application_type    = "web"
}


// ~~~~~~~~~~~~~~~~~~~~~~ KEYVAULT & ACCESS POLICIES ~~~~~~~~~~~~~~~~~~~~~~~~

resource "azapi_resource" "kv" {
  type      = "Microsoft.KeyVault/vaults@2022-07-01"
  name      = var.kvname
  location  = var.location
  parent_id = azurerm_resource_group.rg.id
  body = jsonencode({
    properties = {
      accessPolicies = [
        {
          objectId = "e38a1e64-37f4-45a2-8778-16f63e2cdc49"
          permissions = {
            certificates = [
              "all"
            ]
            keys = [
              "all"
            ]
            secrets = [
              "all"
            ]
            storage = [
              "all"
            ]
          }
          tenantId = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
        },
        {
          objectId = azurerm_app_service.app1.identity.0.principal_id
          permissions = {
            secrets = [
              "get",
              "list"
            ]
          }
          tenantId = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
        }
      ]
      enabledForTemplateDeployment = true
      enableSoftDelete             = false
      sku = {
        family = "A"
        name   = "standard"
      }
      softDeleteRetentionInDays = 7
      tenantId                  = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
      vaultUri                  = "${var.kvname}.vault.azure.net"
    }
  })
}

# ~~~~~~~~~~~~~~~~~~~~~ ADD STORAGE ACCOUNT SECRET ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azapi_resource" "sakey" {
  type      = "Microsoft.KeyVault/vaults/secrets@2022-07-01"
  name      = "storageacckey"
  parent_id = azurerm_resource_group.kv.id
  body = jsonencode({
    properties = {
      attributes = {
        enabled = true
      }
      contentType = "string"
      value       = azurerm_storage_account.storageacc.primary_connection_string
    }
  })
}

# ~~~~~~~~~~~~~~~~~~~~~~ ADD SERVICEBUS NAMESPACE SECRET ~~~~~~~~~~~~~~~~~~~~~~~~

resource "azapi_resource" "sbkey" {
  type      = "Microsoft.KeyVault/vaults/secrets@2022-07-01"
  name      = "servicebuskey"
  parent_id = azurerm_resource_group.kv.id
  body = jsonencode({
    properties = {
      attributes = {
        enabled = true
      }
      contentType = "string"
      value       = azurerm_servicebus_namespace.servicebus.default_primary_connection_string
    }
  })
}

// ~~~~~~~~~~~~~~~~~~~~~~~~ AZURERM KEY VAULT ~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_key_vault" "kv1" {
  enabled_for_template_deployment = true
  location                        = "westeurope"
  name                            = "myterraformvault1"
  resource_group_name             = "terraformrg"
  sku_name                        = "standard"
  soft_delete_retention_days      = 7
  tenant_id                       = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
}

// ~~~~~~~~~~~~~~~~~~~~ AZURERM KV ACCESS POLICY ~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_key_vault_access_policy" "accesspolicy1" {
  key_vault_id = azurerm_key_vault.kv1.id
  tenant_id    = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
  object_id    = "e38a1e64-37f4-45a2-8778-16f63e2cdc49"

  key_permissions = [
    "Get","List"
  ]

  secret_permissions = [
    "Get","List","Set"
  ]
}

// ~~~~~~~~~~~~~~~~~~~~ AZURERM KV ACCESS POLICY ~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_key_vault_access_policy" "accesspolicy2" {
  key_vault_id = azurerm_key_vault.kv1.id
  tenant_id    = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
  object_id    = azurerm_app_service.app1.identity.0.principal_id

  key_permissions = [
    "Get","List"
  ]

  secret_permissions = [
    "Get","List","Set"
  ]
}

// ~~~~~~~~~~~~~~~~~~~~ AZURERM KV ACCESS POLICY ~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_key_vault_access_policy" "accesspolicy3" {
  key_vault_id = azurerm_key_vault.kv1.id
  tenant_id    = "ad5c5b58-e327-4cdb-8f2c-2b534d3ae08b"
  object_id    = "4f2cb568-9bd0-43b8-a855-4ca691808522"

  key_permissions = [
    "Get","List"
  ]

  secret_permissions = [
    "Get","List","Set"
  ]
}

// ~~~~~~~~~~~~~~~~~~~~ AZURERM KV ADD SECRET ~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_key_vault_secret" "storageaccountkey" {
  name         = "sakey1"
  value        = azurerm_storage_account.storageacc.primary_connection_string
  key_vault_id = azurerm_key_vault.kv1.id
}
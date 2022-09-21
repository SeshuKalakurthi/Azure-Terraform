output "primary_connection_string" {
  value     = azurerm_storage_account.storageacc.primary_connection_string
  sensitive = true
}

output "default_primary_connection_string" {
  value     = azurerm_servicebus_namespace.servicebus.default_primary_connection_string
  sensitive = true
}

output "rg" {
  value = azapi_resource.rg.id
}

output "identity" {
  value = azurerm_app_service.app1.identity.0.principal_id
}
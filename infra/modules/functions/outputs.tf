output "webhook_function_url" {
  value = "https://${azurerm_linux_function_app.webhook_receiver.default_hostname}/api/webhook_receiver"
}

output "service_plan_id" {
  value = azurerm_service_plan.main.id
}


output "storage_account_name" {
  value = azurerm_storage_account.functions.name
}

output "storage_account_key" {
  value = azurerm_storage_account.functions.primary_access_key
  sensitive = true
}
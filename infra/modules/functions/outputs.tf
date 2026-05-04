output "webhook_function_url" {
  value = "https://${azurerm_linux_function_app.webhook_receiver.default_hostname}/api/webhook_receiver"
}
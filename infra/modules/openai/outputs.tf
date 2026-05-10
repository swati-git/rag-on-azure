output "endpoint" {
  value = azurerm_cognitive_account.main.endpoint
}

output "id" {
  value = azurerm_cognitive_account.main.id
}

output "embedding_deployment_name" {
  value = azurerm_cognitive_deployment.embedding.name
}
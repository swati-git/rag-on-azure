output "search_endpoint" {
  value = "https://${azurerm_search_service.search.name}.search.windows.net"
}

output "search_service_id" {
  value = azurerm_search_service.search.id
}

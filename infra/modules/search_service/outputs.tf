output "search_endpoint" {
  value = "https://${azurerm_search_service.search.name}.search.windows.net"
}
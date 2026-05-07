
resource "azurerm_search_service" "search" {
  name                = "${var.project}-search-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "basic"       
  replica_count       = 1
  partition_count     = 1
  local_authentication_enabled = false
}
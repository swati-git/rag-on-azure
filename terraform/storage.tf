resource "azurerm_storage_account" "storage_account_rag" {
  name                     = "documentstore"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = {
    Environment = var.environment
    Purpose     = "rag-document-source"
  }
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_id    = azurerm_storage_account.storage_account_rag.id
  container_access_type = "private"
}

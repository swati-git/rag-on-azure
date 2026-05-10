data "azurerm_key_vault_secret" "confluence_api_token" {
  name         = "confluence-api-token"
  key_vault_id = module.keyvault.vault_id
}

data "azurerm_key_vault_secret" "confluence_email" {
  name         = "confluence-email"
  key_vault_id = module.keyvault.vault_id
}

data "azurerm_key_vault_secret" "confluence_base_url" {
  name         = "confluence-base-url"
  key_vault_id = module.keyvault.vault_id
}


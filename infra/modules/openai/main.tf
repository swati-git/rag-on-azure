resource "azurerm_cognitive_account" "main" {
  name                = "${var.project}-openai-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "OpenAI"
  sku_name            = "S0"

  custom_subdomain_name = "${var.project}-openai-${var.environment}"
  network_acls {
    default_action = "Allow"     
    ip_rules       = []
  }

  
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "text-embedding-3-small"
  cognitive_account_id = azurerm_cognitive_account.main.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  sku {
    name = "GlobalStandard"
    capacity = 30
  }


}
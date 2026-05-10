resource "azurerm_key_vault" "main" {
  name                = "${var.project}-kv-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # allow terraform caller to read/write secrets during apply
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.terraform_caller_object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover"
    ]
  }

  # prevent accidental deletion
  soft_delete_retention_days = 7
  purge_protection_enabled   = false   # set true in production
}
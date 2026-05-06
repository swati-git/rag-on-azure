resource "azurerm_storage_account" "functions" {
  name                     = "${var.project}sa${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "main" {
  name                = "${var.project}-asp-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"  
}

resource "azurerm_linux_function_app" "webhook_receiver" {
  name                       = "${var.project}-webhook-${var.environment}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.functions.name
  storage_account_access_key = azurerm_storage_account.functions.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    # Service Bus connection string for publishing messages
    "SERVICE_BUS_CONNECTION_STR" = var.service_bus_connection_str
    "SERVICE_BUS_QUEUE_NAME"     = "confluence-page-events"

    # Required Azure Functions settings
    "FUNCTIONS_WORKER_RUNTIME"        = "python"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"  = "true"
    "AzureWebJobsFeatureFlags"        = "EnableWorkerIndexing"
  }
}
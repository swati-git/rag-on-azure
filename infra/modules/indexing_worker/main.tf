resource "azurerm_linux_function_app" "indexing_worker" {
  name                       = "${var.project}-indexer-${var.environment}"
  resource_group_name        = var.resource_group_name
  location                   = var.location

  # shared infrastructure — received as variables from root
  service_plan_id            = var.service_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "AzureWebJobsFeatureFlags"              = "EnableWorkerIndexing"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"        = "true"
    "SERVICE_BUS_CONNECTION_STR"            = var.service_bus_connection_str
    "SERVICE_BUS_QUEUE_NAME"               = "confluence-page-events"
    "SEARCH_ENDPOINT"                       = var.search_endpoint
    "SEARCH_INDEX_NAME"                     = "confluence-pages"

  }
}
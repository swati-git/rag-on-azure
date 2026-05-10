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
    "SERVICE_BUS_QUEUE_NAME"                = "confluence-page-events"
    "SEARCH_ENDPOINT"                       = var.search_endpoint
    "SEARCH_INDEX_NAME"                     = "confluence-pages"
    "AZURE_OPENAI_EMBEDDING_MODEL"          = var.azure_openai_embedding_model

  }

  identity {
    type = "SystemAssigned" 
  }
}

resource "azurerm_role_assignment" "indexer_search_access" {
  scope                =   var.search_service_id
  role_definition_name =   "Search Index Data Contributor"
  principal_id         =   azurerm_linux_function_app.indexing_worker.identity[0].principal_id
}

resource "azurerm_role_assignment" "indexer_openai_access" {
  scope                = var.azure_openai_id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_linux_function_app.indexing_worker.identity[0].principal_id
}


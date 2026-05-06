
resource "azurerm_search_service" "search" {
  name                = "${var.project}-search-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "basic"       
  replica_count       = 1
  partition_count     = 1
  local_authentication_enabled = false
}

resource "azurerm_linux_function_app" "indexing_worker" {
  name                       = "${var.project}-indexer-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  service_plan_id            = module.functions.service_plan_id
  storage_account_name       = module.functions.storage_account_name
  storage_account_access_key = module.functions.storage_account_key

  identity {
    type = "SystemAssigned"
  }  

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "AzureWebJobsFeatureFlags"       = "EnableWorkerIndexing"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"

  
    "SERVICE_BUS_CONNECTION_STR"     = module.service_bus.primary_connection_string
    "SERVICE_BUS_QUEUE_NAME"         = "confluence-page-events"

  
    "CONFLUENCE_BASE_URL"            = var.confluence_base_url
    "CONFLUENCE_EMAIL"               = var.confluence_email
    "CONFLUENCE_API_TOKEN"           = var.confluence_api_token

    
    "SEARCH_ENDPOINT"                = module.search.endpoint
    "SEARCH_API_KEY"                 = module.search.primary_key
    "SEARCH_INDEX_NAME"              = "confluence-pages"

    
    "AZURE_OPENAI_ENDPOINT"          = var.azure_openai_endpoint
    "AZURE_OPENAI_API_KEY"           = var.azure_openai_api_key
    "AZURE_OPENAI_EMBEDDING_MODEL"   = var.azure_openai_embedding_model
  }
}

resource "azurerm_role_assignment" "search_index_contributor" {
  scope              = azurerm_search_service.search.id
  role_definition_name = "Search Index Data Contributor"
  principal_id       = azurerm_linux_function_app.indexing_worker.identity[0].principal_id
}

resource "azurerm_role_assignment" "search_service_contributor" {
  scope              = azurerm_search_service.search.id
  role_definition_name = "Search Service Contributor"
  principal_id       = azurerm_linux_function_app.indexing_worker.identity[0].principal_id
}

resource "azurerm_role_assignment" "search_service_contributor" {
  scope              = azurerm_search_service.search.id
  role_definition_name = "Search Index Data Reader"
  principal_id       = azurerm_linux_function_app.indexing_worker.identity[0].principal_id
}
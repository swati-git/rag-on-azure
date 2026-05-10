terraform {
    required_version = "1.14.8"
    required_providers {
        azurerm  = {
             source  = "hashicorp/azurerm"
             version  = "=4.70.0"

        }
    }
}

provider azurerm {
    features{}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project}-rg-${var.environment}"
  location = var.location
}

module "service_bus" {
  source              = "./modules/service_bus"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  environment         = var.environment
}

module "functions" {
  source                      = "./modules/functions"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = var.location
  project                     = var.project
  environment                 = var.environment
  service_bus_connection_str  = module.service_bus.primary_connection_string
}

module "search_service" {
  source                      = "./modules/search_service"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = var.location
  project                     = var.project
  environment                 = var.environment
}

module "indexing_worker" {
  source              = "./modules/indexing_worker"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  environment         = var.environment

  # ── from module.functions outputs ──────────────────────────────────────────
  service_plan_id              = module.functions.service_plan_id
  storage_account_name         = module.functions.storage_account_name
  storage_account_key          = module.functions.storage_account_key

  # ── from module.service_bus outputs ──────────────────────────────────────────
  service_bus_connection_str = module.functions.storage_account_key

  # ── from module.search outputs ─────────────────────────────────────────────
  search_endpoint              = module.search_service.search_endpoint
  search_service_id            = module.search_service.search_service_id
 
  
  confluence_base_url          = data.azurerm_key_vault_secret.confluence_base_url.value
  confluence_email             = data.azurerm_key_vault_secret.confluence_email.value
  confluence_api_token         = data.azurerm_key_vault_secret.confluence_api_token.value
  
  azure_openai_endpoint        = module.openai.endpoint
  azure_openai_embedding_model = module.openai.embedding_deployment_name
  azure_openai_id              = module.openai.id

}

data "azurerm_client_config" "current" {}

module "keyvault" {
  source                     = "./modules/keyvault"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = var.location
  project                    = var.project
  environment                = var.environment
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  terraform_caller_object_id = data.azurerm_client_config.current.object_id
}


module "openai" {
  source              = "./modules/openai"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  project             = var.project
  environment         = var.environment
}
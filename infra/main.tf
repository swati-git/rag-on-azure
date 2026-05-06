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

}


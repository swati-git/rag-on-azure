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


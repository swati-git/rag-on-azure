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


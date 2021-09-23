terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  
  #subscription_id = "${env.ARM_SUBSCRIPTION_ID}"
  #tenant_id         = "${env.ARM_TENNANT_ID}"
  #client_id         = "${env.CLIENT_ID}"
  #client_secret     = "${env.ARM_CLIENT_SECRET}"
}

resource "azurerm_resource_group" "joeyaxtell-sample-website" {
  name     = "joeyaxtell-sample-website-rg"
  location = "central US"
}

resource "azurerm_app_service_plan" "joeyaxtell-sample-website" {
  name                = "joeyaxtell-sample-website-appserviceplan"
  location            = azurerm_resource_group.joeyaxtell-sample-website.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "joeyaxtell-sample-website" {
  name                = "joeyaxtell-sample-website-app-service"
  location            = azurerm_resource_group.joeyaxtell-sample-website.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website.name
  app_service_plan_id = azurerm_app_service_plan.joeyaxtell-sample-website.id

  site_config {
    dotnet_framework_version = "v5.0"
  #  scm_type                 = "GitHub"
  }
}
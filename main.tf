terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.77.0"
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
  kind = "Linux"
  reserved = "true"

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
    linux_fx_version  = "DOTNETCORE|3.1"
    #scm_type = "GitHub"
   }
}

resource "azurerm_app_service_source_control_token" "joeyaxtell-sample-website" {
  type  = "GitHub"
#  token = "" ##NEED TO TOKENIZE
}

resource "azurerm_app_service_source_control" "joeyaxtell-sample-website" {
  app_id   = azurerm_app_service.joeyaxtell-sample-website.id
  repo_url = "https://github.com/thos25/Sample-Website"
  branch   = "main"
}

### Configure App Service Plan auto-scaling out and in

resource "azurerm_monitor_autoscale_setting" "joeyaxtell-sample-website" {
  name                = "myAutoscaleSetting"
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website.name
  location            = azurerm_resource_group.joeyaxtell-sample-website.location
  target_resource_id  = azurerm_app_service_plan.joeyaxtell-sample-website.id
  profile {
    name = "default"
    capacity {
      default = 1
      minimum = 1
      maximum = 3
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.joeyaxtell-sample-website.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_app_service_plan.joeyaxtell-sample-website.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 10
      }
      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }  
}
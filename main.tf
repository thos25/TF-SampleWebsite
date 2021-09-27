###########################################################################
#####                   Terraform Deploy for Sapmle Website            ####
####    Created by:  Joey Axtell                                       ####
####    Last Modified:  09/25/2021                                     ####
####    Description:  Deploy resource group, app service, app service  ####
####                  plan, CI/CD pipeline, and autoscale settings for ####
####                  sample-website being deployed to Azure.          ####
###########################################################################
 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.77.0"
    }
  }
}

# Configure the Microsoft Azurerm Provider
provider "azurerm" {
  features {}
}

# Create resource group for all project objects in Azure
resource "azurerm_resource_group" "joeyaxtell-sample-website" {
  name     = var.rg1_name
  location = var.az_location
}

#Resource group for app insights resources
resource "azurerm_resource_group" "joeyaxtell-sample-website-appinsights" {
  name     = var.apprg_name
  location = var.az_location
}

resource "azurerm_resource_group" "joeyaxtell-sample-website-secondary" {
  name     = var.rg2_name
  location = var.az_2nd_location
}

#Create app service plan, specifying OS and SKU
resource "azurerm_app_service_plan" "joeyaxtell-sample-website" {
  name                = var.appsp_name
  location            = azurerm_resource_group.joeyaxtell-sample-website.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website.name
  kind = "Linux"
  reserved = "true"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

#Create app service plan, specifying OS and SKU
resource "azurerm_app_service_plan" "joeyaxtell-sample-website-secondary" {
  name                = "${var.appsp_name}-secondary"
  location            = azurerm_resource_group.joeyaxtell-sample-website-secondary.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website-secondary.name
  kind = "Linux"
  reserved = "true"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

#Create App service and define dotnetcore version 3.1 ans build environment
resource "azurerm_app_service" "joeyaxtell-sample-website" {
  name                = var.appsvc_name
  location            = azurerm_resource_group.joeyaxtell-sample-website.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website.name
  app_service_plan_id = azurerm_app_service_plan.joeyaxtell-sample-website.id

  site_config {
    linux_fx_version  = "DOTNETCORE|3.1"
    #scm_type = "GitHub"
   }

  app_settings = {
     "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.joeyaxtell-sample-website-appinsights.instrumentation_key}"
     "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
     "XDT_MicrosoftApplicationInsights_Mode" = "recommended"
  }
}

# Secondary app_service in secondary location
resource "azurerm_app_service" "joeyaxtell-sample-website-secondary" {
  name                = "${var.appsvc_name}-secondary"
  location            = azurerm_resource_group.joeyaxtell-sample-website-secondary.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website-secondary.name
  app_service_plan_id = azurerm_app_service_plan.joeyaxtell-sample-website-secondary.id

  site_config {
    linux_fx_version  = "DOTNETCORE|3.1"
    #scm_type = "GitHub"
   }

  app_settings = {
     "APPINSIGHTS_INSTRUMENTATIONKEY" = "${azurerm_application_insights.joeyaxtell-sample-website-appinsights.instrumentation_key}"
     "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
     "XDT_MicrosoftApplicationInsights_Mode" = "recommended"
  }
}

#Configure Azure to use GitHub OAuth token for authenitcation
resource "azurerm_app_service_source_control_token" "joeyaxtell-sample-website" {
  type  = "GitHub"
  token = var.Github_OAuth ##NEED TO TOKENIZE
}

#Setup CI/CD pipeline from app service to Github.  This requires Azurerm 3.0 today
resource "azurerm_app_service_source_control" "joeyaxtell-sample-website" {
  app_id   = azurerm_app_service.joeyaxtell-sample-website.id
  repo_url = var.repo_url
  branch   = "main"
}

#Setup CI/CD pipeline from secondary app service to Github.  This requires Azurerm 3.0 today
resource "azurerm_app_service_source_control" "joeyaxtell-sample-website-secondary" {
  app_id   = azurerm_app_service.joeyaxtell-sample-website-secondary.id
  repo_url = var.repo_url
  branch   = "main"
}

# Configure App Service Plan auto-scaling out and in

resource "azurerm_monitor_autoscale_setting" "joeyaxtell-sample-website" {
  name                = var.autoscale_name
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

# Configure Secondary App Service Plan auto-scaling out and in

resource "azurerm_monitor_autoscale_setting" "joeyaxtell-sample-website-secondary" {
  name                = "${var.autoscale_name}-secondary"
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website-secondary.name
  location            = azurerm_resource_group.joeyaxtell-sample-website-secondary.location
  target_resource_id  = azurerm_app_service_plan.joeyaxtell-sample-website-secondary.id
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
        metric_resource_id = azurerm_app_service_plan.joeyaxtell-sample-website-secondary.id
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
        metric_resource_id = azurerm_app_service_plan.joeyaxtell-sample-website-secondary.id
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

resource "azurerm_log_analytics_workspace" "joeyaxtell-sample-website-loganalytics" {
  name                = "joeyaxtell-sample-website-loganalytics"
  location            = azurerm_resource_group.joeyaxtell-sample-website-appinsights.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website-appinsights.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "joeyaxtell-sample-website-appinsights" {
  name                = "joyeaxtell-sample-website-appinsights"
  location            = azurerm_resource_group.joeyaxtell-sample-website-appinsights.location
  resource_group_name = azurerm_resource_group.joeyaxtell-sample-website-appinsights.name
  workspace_id        = azurerm_log_analytics_workspace.joeyaxtell-sample-website-loganalytics.id
  application_type    = "web"
}

# Setup for Azure Front Door load balancer
resource "azurerm_frontdoor" "joeyaxtell-sample-website" {
  name                                         = var.frontdoor_name
  resource_group_name                          = azurerm_resource_group.joeyaxtell-sample-website.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "joeyaxtell-sample-website-routingrule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["joeyaxtell-sample-website-frontdoor-frontend"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = var.frontdoor_backend_pool
    }
  }

  backend_pool_load_balancing {
    name = "joeyaxtell-sample-website-frontdoor-loadbalancer"
  }

  backend_pool_health_probe {
    name = "joeyaxtell-sample-website-frontdoor-healthprobe"
    protocol = "Https"
    interval_in_seconds = 30
  }

  backend_pool {
    name = var.frontdoor_backend_pool
    backend {
      host_header = "${var.appsvc_name}.azurewebsites.net"
      address     = "${var.appsvc_name}.azurewebsites.net"
      http_port   = 80
      https_port  = 443
    }
    backend {
      host_header = "${var.appsvc_name}-secondary.azurewebsites.net"
      address     = "${var.appsvc_name}-secondary.azurewebsites.net"
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "joeyaxtell-sample-website-frontdoor-loadbalancer"
    health_probe_name   = "joeyaxtell-sample-website-frontdoor-healthprobe"
  }

  frontend_endpoint {
    name      = "joeyaxtell-sample-website-frontdoor-frontend"
    host_name = "joeyaxtell-sample-website-frontdoor.azurefd.net"
  }
}
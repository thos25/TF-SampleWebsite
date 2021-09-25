variable "rg_name" {
  description = "Value of the Name tag for the resource group"
  type        = string
  default     = "joeyaxtell-sample-website-rg"
}

variable "az_location" {
  description = "Value of the location field defining where Azure resources are deployed"
  type        = string
  default     = "central US"
}

variable "appsp_name" {
  description = "Value of the Name tag for the app service plan"
  type        = string
  default     = "joeyaxtell-sample-website-appserviceplan"
}

variable "appsvc_name" {
  description = "Value of the Name tag for the app service"
  type        = string
  default     = "joeyaxtell-sample-website-app-service"
}

variable "repo_url" {
  description = "Value of the repo_url for the app service source control resource"
  type        = string
  default     = "https://github.com/thos25/Sample-Website"
}

variable "autoscale_name" {
  description = "Value of the Name tag for the autoscale setting"
  type        = string
  default     = "joeyaxtell-sample-website-autoscale-settings"
}
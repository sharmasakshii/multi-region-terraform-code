terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.104.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "1fc66efc-2ddc-4018-a0d6-a513dc7f219c"
}

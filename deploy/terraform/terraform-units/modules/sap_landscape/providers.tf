# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.main, azurerm.deployerspn, azurerm.dnsmanagement, azurerm.privatelinkdnsmanagement]
    }

    azapi = {
      source                = "azure/azapi"
      configuration_aliases = [azapi.api]
    }
  }
}

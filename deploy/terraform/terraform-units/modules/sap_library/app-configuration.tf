# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                          Azure App Configuration                             #
#                                                                              #
#######################################4#######################################8

data  "azurerm_app_configuration" "app_config" {
  count                                = local.application_configuration_deployed ? 1 : 0
  provider                             = azurerm.deployer
  name                                 = local.app_config_name
  resource_group_name                  = local.app_config_resource_group_name
}

data "azurerm_app_configuration_key" "deployer_network_id" {
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_Deployer_network_id", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
}


resource "azurerm_app_configuration_key" "libraryStateFileName" {
  provider                             = azurerm.deployer
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_LibraryStateFileName", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = format("%s-SAP_LIBRARY.terraform.tfstate",var.naming.prefix.LIBRARY)
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}


resource "azurerm_app_configuration_key" "terraformRemoteStateStorageAccountId" {
  provider                             = azurerm.deployer
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_TerraformRemoteStateStorageAccountId", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = var.storage_account_tfstate.exists ? (
                                                            data.azurerm_storage_account.storage_tfstate[0].id) : (
                                                            try(azurerm_storage_account.storage_tfstate[0].id, "")
                                                          )
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}


resource "azurerm_app_configuration_key" "SAPLibraryStorageAccountId" {
  provider                             = azurerm.deployer
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_SAPLibraryStorageAccountId", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = var.storage_account_tfstate.exists ? (
                                                            data.azurerm_storage_account.storage_sapbits[0].id) : (
                                                            try(azurerm_storage_account.storage_sapbits[0].id, "")
                                                          )
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "SAPMediaPath" {
  provider                             = azurerm.deployer
  count                                = local.application_configuration_deployed ? 1 : 0
  configuration_store_id               = data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_SAPMediaPath", var.deployer.control_plane_name)
  label                                = var.deployer.control_plane_name
  value                                = format("https://%s.blob.core.windows.net/%s", var.storage_account_sapbits.exists ?
                                                             split("/", var.storage_account_sapbits.id)[8] : local.storage_account_SAPmedia,
                                                             var.storage_account_sapbits.sapbits_blob_container.name)
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = merge(var.infrastructure.tags, {
                                           "source" = "SAPLibrary"
                                         }  )
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}
locals {
  application_configuration_deployed   = var.deployer.use ? length(try(var.deployer_tfstate.deployer_app_config_id, var.deployer.application_configuration_id )) > 0 : length(var.deployer.application_configuration_id ) > 0
  parsed_id                            = local.application_configuration_deployed ? provider::azurerm::parse_resource_id(coalesce(var.deployer.application_configuration_id, try(var.deployer_tfstate.deployer_app_config_id, ""))) : null
  app_config_name                      = local.application_configuration_deployed ? local.parsed_id["resource_name"] : ""
  app_config_resource_group_name       = local.application_configuration_deployed ? local.parsed_id["resource_group_name"] : ""
}

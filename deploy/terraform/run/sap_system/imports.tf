# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


/*
    Description:
    Retrieve remote tfstate file of Deployer and current environment's SPN
*/


data "azurerm_client_config" "current" {}

data "terraform_remote_state" "deployer"             {
                                                       backend       = "azurerm"
                                                       count         = length(try(var.deployer_tfstate_key, "")) > 0 ? 1 : 0
                                                       config        = {
                                                                         resource_group_name  = local.SAPLibrary_resource_group_name
                                                                         storage_account_name = local.tfstate_storage_account_name
                                                                         container_name       = local.tfstate_container_name
                                                                         key                  = var.deployer_tfstate_key
                                                                         subscription_id      = local.SAPLibrary_subscription_id
                                                                       }
}

data "terraform_remote_state" "landscape"            {
                                                       backend       = "azurerm"
                                                       config        = {
                                                                         resource_group_name  = local.SAPLibrary_resource_group_name
                                                                         storage_account_name = local.tfstate_storage_account_name
                                                                         container_name       = "tfstate"
                                                                         key                  = var.landscape_tfstate_key
                                                                         subscription_id      = local.SAPLibrary_subscription_id
                                                                       }
                                                     }

data "azurerm_app_configuration_key" "media_path"    {
                                                        count                  = length(coalesce(var.application_configuration_id,try(data.terraform_remote_state.landscape.outputs.application_configuration_id, " "))) == 1 ? 0 : 1
                                                        configuration_store_id = coalesce(var.application_configuration_id,try(data.terraform_remote_state.landscape.outputs.application_configuration_id, " "))
                                                        key                    = format("%s_SAPMediaPath", coalesce(var.control_plane_name, try(data.terraform_remote_state.landscape.outputs.control_plane_name, "")))
                                                        label                  = coalesce(var.control_plane_name, try(data.terraform_remote_state.landscape.outputs.control_plane_name, ""))
                                                      }



data "azurerm_key_vault_secret" "subscription_id" {
  count                                = length(var.subscription_id) > 0 ? 0 : (var.use_spn ? 1 : 0)
  name                                 = format("%s-subscription-id", module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "client_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_subscription_id" {
  name                                 = format("%s-subscription-id", data.terraform_remote_state.deployer[0].outputs.control_plane_name)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_client_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-id", data.terraform_remote_state.deployer[0].outputs.control_plane_name)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", data.terraform_remote_state.deployer[0].outputs.control_plane_name)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

data "azurerm_key_vault_secret" "cp_tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", data.terraform_remote_state.deployer[0].outputs.control_plane_name)
  key_vault_id                         = local.spn_key_vault_arm_id
  timeouts                             {
                                          read = "1m"
                                       }
}

// Import current service principal
data "azuread_service_principal" "sp"                 {
                                                        count        = try(data.terraform_remote_state.landscape.outputs.use_spn, true) && var.use_spn ? 1 : 0
                                                        client_id    = local.spn.client_id
                                                      }



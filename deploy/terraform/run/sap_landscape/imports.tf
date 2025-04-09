# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/*
    Description:
    Retrieve remote tfstate file of Deployer and current environment's SPN
*/


data "azurerm_client_config" "current" {}

data "azurerm_client_config" "current_main" {
  provider                            = azurerm.workload

}

data "azurerm_app_configuration_key" "deployer_state_file" {
  count                  = length(data.terraform_remote_state.deployer[0].outputs.deployer_app_config_id) > 0 ? 1 : 0
  configuration_store_id = data.terraform_remote_state.deployer[0].outputs.deployer_app_config_id
  key                    = format("%s_StateFileName", local.control_plane_name)
  label                  = local.control_plane_name
}

data "terraform_remote_state" "deployer" {
  backend                              = "azurerm"

  count                                = var.use_deployer && length(try(var.deployer_tfstate_key, "")) > 0 ? 1 : 0
  config                               = {
                                           resource_group_name  = local.SAPLibrary_resource_group_name
                                           storage_account_name = local.tfstate_storage_account_name
                                           container_name       = local.tfstate_container_name
                                           key                  = trimspace(var.deployer_tfstate_key)
                                           subscription_id      = local.SAPLibrary_subscription_id

                                         }
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
}

ephemeral "azurerm_key_vault_secret" "client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE)
  key_vault_id                         = local.spn_key_vault_arm_id
}

data "azurerm_key_vault_secret" "tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", module.sap_namegenerator.naming.prefix.WORKLOAD_ZONE)
  key_vault_id                         = local.spn_key_vault_arm_id

}

data "azurerm_key_vault_secret" "cp_subscription_id" {
  count                                = length(try(data.terraform_remote_state.deployer[0].outputs.environment, "")) > 0 ?  (var.use_spn ? 1 : 0) : 0
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

}

ephemeral "azurerm_key_vault_secret" "cp_client_secret" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-client-secret", data.terraform_remote_state.deployer[0].outputs.control_plane_name)
  key_vault_id                         = local.spn_key_vault_arm_id
}

data "azurerm_key_vault_secret" "cp_tenant_id" {
  count                                = var.use_spn ? 1 : 0
  name                                 = format("%s-tenant-id", data.terraform_remote_state.deployer[0].outputs.control_plane_name)
  key_vault_id                         = local.spn_key_vault_arm_id
}


# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                          Azure App Configuration                             #
#                                                                              #
#######################################4#######################################8


resource "azurerm_app_configuration" "app_config" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? length(var.infrastructure.application_configuration_id) > 0 ? 0 : 1 : 0
  name                                 = var.app_config_service_name
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  sku =                                "standard"
}

data "azurerm_app_configuration" "app_config" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? length(var.infrastructure.application_configuration_id) > 0 ? 1 : 0 : 0
  name                                 = local.app_config_name
  resource_group_name                  = local.app_config_resource_group_name
}
resource "azurerm_role_assignment" "appconf_dataowner" {
  provider                             = azurerm.main
  count                                = var.bootstrap && var.infrastructure.deploy_application_configuration ? 1 : 0
  scope                                = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  role_definition_name                 = "App Configuration Data Owner"
  principal_id                         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "appconf_dataowner_msi" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  scope                                = var.infrastructure.deploy_application_configuration ? (
                                          length(var.infrastructure.application_configuration_id) == 0 ? (
                                            azurerm_app_configuration.app_config[0].id) : (
                                            data.azurerm_app_configuration.app_config[0].id)) : (
                                          0
                                          )
  role_definition_name                 = "App Configuration Data Owner"
  principal_id                         = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id

}

resource "time_sleep" "wait_for_appconf_dataowner_assignment" {
  create_duration                      = "60s"

  depends_on                           = [
                                           azurerm_role_assignment.appconf_dataowner_msi,
                                           azurerm_role_assignment.appconf_dataowner
                                         ]
}

resource "azurerm_app_configuration_key" "deployer_state_file_name" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id

  key                                  = format("%s_StateFileName", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = format("%s-INFRASTRUCTURE.terraform.tfstate",var.state_filename_prefix)
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "deployer_keyvault_name" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id

  key                                  = format("%s_KeyVaultName", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].name : azurerm_key_vault.kv_user[0].name
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }

}

resource "azurerm_app_configuration_key" "deployer_keyvault_id" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_KeyVaultResourceId", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = var.key_vault.exists ? data.azurerm_key_vault.kv_user[0].id : azurerm_key_vault.kv_user[0].id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }

}

resource "azurerm_app_configuration_key" "deployer_resourcegroup_name" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_ResourceGroupName", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = local.resourcegroup_name
  content_type                         = "text/plain"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "deployer_subscription_id" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_SubscriptionId", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = data.azurerm_subscription.primary.subscription_id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "web_application_resource_id" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? var.webapp_deployment ? 1 :0 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_AppServiceId", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = try(azurerm_windows_web_app.webapp[0].id, "")
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_app_configuration_key" "web_application_identity_id" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? var.app_service.use ? 1 :0 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_AppServiceIdentityId", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = try(azurerm_windows_web_app.webapp[0].identity[0].principal_id, "")
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}


resource "azurerm_app_configuration_key" "deployer_msi_id" {
  provider                             = azurerm.main
  count                                = var.infrastructure.deploy_application_configuration ? 1 : 0
  depends_on                           = [
                                            time_sleep.wait_for_appconf_dataowner_assignment,
                                            azurerm_private_endpoint.app_config
                                         ]

  configuration_store_id               = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
  key                                  = format("%s_Deployer_MSI_Id", var.state_filename_prefix)
  label                                = var.state_filename_prefix
  value                                = length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].principal_id : data.azurerm_user_assigned_identity.deployer[0].principal_id
  content_type                         = "text/id"
  type                                 = "kv"
  tags                                 = {
                                           "source" = "Deployer"
                                         }
  lifecycle {
              ignore_changes = [
                configuration_store_id,
                etag,
                id
              ]
            }
}

resource "azurerm_private_endpoint" "app_config" {
  provider                             = azurerm.main
  count                                = !var.bootstrap && var.use_private_endpoint && var.infrastructure.deploy_application_configuration ? 1 : 0
  name                                 = format("%s%s%s",
                                          var.naming.resource_prefixes.appconfig_private_link,
                                          local.prefix,
                                          var.naming.resource_suffixes.appconfig_private_link
                                        )
  resource_group_name                  = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].name) : (
                                           azurerm_resource_group.deployer[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                           data.azurerm_resource_group.deployer[0].location) : (
                                           azurerm_resource_group.deployer[0].location
                                         )
  subnet_id                            = local.management_subnet_exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].id) : (
                                           azurerm_subnet.subnet_mgmt[0].id
                                                                          )
  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.appconfig_private_link,
                                           local.prefix,
                                           var.naming.resource_suffixes.appconfig_private_link,
                                           var.naming.resource_suffixes.nic
                                         )

  private_service_connection {
                               name                           = format("%s%s%s",
                                                                  var.naming.resource_prefixes.appconfig_private_svc,
                                                                  local.prefix,
                                                                  var.naming.resource_suffixes.appconfig_private_svc
                                                                )
                               is_manual_connection           = false
                               private_connection_resource_id = length(var.infrastructure.application_configuration_id) == 0 ? azurerm_app_configuration.app_config[0].id : data.azurerm_app_configuration.app_config[0].id
                               subresource_names              = [
                                                                  "configurationStores"
                                                                ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0)
                                     content {
                                               name                 = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
                                               private_dns_zone_ids = [data.azurerm_private_dns_zone.appconfig[0].id]
                                             }
                                   }

}


data "azurerm_private_dns_zone" "appconfig" {
  provider                             = azurerm.privatelinkdnsmanagement
  count                                = !var.bootstrap && var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0
  name                                 = var.dns_settings.dns_zone_names.appconfig_dns_zone_name
  resource_group_name                  = coalesce(
                                           var.dns_settings.privatelink_dns_resourcegroup_name,
                                           var.dns_settings.management_dns_resourcegroup_name,
                                           var.dns_settings.local_dns_resourcegroup_name)

}

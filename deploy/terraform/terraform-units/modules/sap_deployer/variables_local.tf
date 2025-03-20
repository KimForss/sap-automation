# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


###############################################################################
#                                                                             #
#                            Local Variables                                  #
#                                                                             #
###############################################################################


locals {

  storageaccount_names                 = var.naming.storageaccount_names.DEPLOYER
  virtualmachine_names                 = var.naming.virtualmachine_names.DEPLOYER
  keyvault_names                       = var.naming.keyvault_names.DEPLOYER

  // Default option(s):
  enable_secure_transfer               = try(var.options.enable_secure_transfer, true)
  enable_deployer_public_ip            = try(var.options.enable_deployer_public_ip, false)
  Agent_IP                             = try(var.Agent_IP, "")


  // Resource group
  prefix                               = var.naming.prefix.DEPLOYER

  resource_group_exists                = length(var.infrastructure.resource_group.arm_id) > 0
  // If resource ID is specified extract the resourcegroup name from it otherwise read it either from input of create using the naming convention
  resourcegroup_name                   = local.resource_group_exists ? (
                                           split("/", var.infrastructure.resource_group.arm_id)[4]) : (
                                           length(var.infrastructure.resource_group.name) > 0 ? (
                                             var.infrastructure.resource_group.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_rg,
                                               local.prefix,
                                               var.naming.resource_suffixes.deployer_rg
                                             )
                                           )
                                         )
  rg_appservice_location               = local.resource_group_exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  // Post fix for all deployed resources
  postfix                              = random_id.deployer.hex

  // Management vnet
  vnet_mgmt_arm_id                     = try(var.infrastructure.vnets.management.arm_id, "")
  management_virtual_network_exists                     = length(local.vnet_mgmt_arm_id) > 0

  // If resource ID is specified extract the vnet name from it otherwise read it either from input of create using the naming convention
  vnet_mgmt_name                      = local.management_virtual_network_exists ? (
                                          split("/", local.vnet_mgmt_arm_id)[8]) : (
                                          length(var.infrastructure.vnets.management.name) > 0 ? (
                                            var.infrastructure.vnets.management.name) : (
                                            format("%s%s%s",
                                              var.naming.resource_prefixes.vnet,
                                              length(local.prefix) > 0 ? (
                                                local.prefix) : (
                                                var.infrastructure.environment
                                              ),
                                              var.naming.resource_suffixes.vnet
                                            )
                                          )
                                        )

  vnet_mgmt_addr                       = local.management_virtual_network_exists ? "" : try(var.infrastructure.vnets.management.address_space, "")

  // Management subnet
  management_subnet_arm_id             = try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, "")
  management_subnet_exists             = length(local.management_subnet_arm_id) > 0

  // If resource ID is specified extract the subnet name from it otherwise read it either from input of create using the naming convention
  management_subnet_name               = local.management_subnet_exists ? (
                                           split("/", var.infrastructure.vnets.management.subnet_mgmt.arm_id)[10]) : (
                                           length(var.infrastructure.vnets.management.subnet_mgmt.name) > 0 ? (
                                             var.infrastructure.vnets.management.subnet_mgmt.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_subnet,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.deployer_subnet
                                             )
                                         ))

  management_subnet_prefix             = local.management_subnet_exists ? (
                                           "") : (
                                           try(var.infrastructure.vnets.management.subnet_mgmt.prefix, "")
                                         )
  management_subnet_deployed_prefixes  = local.management_subnet_exists ? (
                                           data.azurerm_subnet.subnet_mgmt[0].address_prefixes) : (
                                           try(azurerm_subnet.subnet_mgmt[0].address_prefixes, [])
                                         )

  // Management NSG
  management_subnet_nsg_arm_id         = try(var.infrastructure.vnets.management.subnet_mgmt.nsg.arm_id, "")
  management_subnet_nsg_exists         = length(local.management_subnet_nsg_arm_id) > 0
  // If resource ID is specified extract the nsg name from it otherwise read it either from input of create using the naming convention
  management_subnet_nsg_name           = local.management_subnet_nsg_exists ? (
                                           split("/", local.management_subnet_nsg_arm_id)[8]) : (
                                           length(var.infrastructure.vnets.management.subnet_mgmt.nsg.name) > 0 ? (
                                             var.infrastructure.vnets.management.subnet_mgmt.nsg.name) : (
                                             format("%s%s%s",
                                               var.naming.resource_prefixes.deployer_subnet_nsg,
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                               var.naming.resource_suffixes.deployer_subnet_nsg
                                             )
                                         ))

  management_subnet_nsg_allowed_ips    = local.management_subnet_nsg_exists ? (
                                           []) : (
                                           length(var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips) > 0 ? (
                                             var.infrastructure.vnets.management.subnet_mgmt.nsg.allowed_ips) : (
                                             ["0.0.0.0/0"]
                                           )
                                         )

  // Firewall subnet
  firewall_subnet_arm_id               = try(var.infrastructure.vnets.management.subnet_fw.arm_id, "")
  firewall_subnet_exists               = length(local.firewall_subnet_arm_id) > 0
  firewall_subnet_name                 = "AzureFirewallSubnet"
  firewall_subnet_prefix               = local.firewall_subnet_exists ? (
                                           "") : (
                                           try(var.infrastructure.vnets.management.subnet_fw.prefix, "")
                                         )

  # Not all region names are the same as their service tags
  # https://docs.microsoft.com/en-us/azure/virtual-network/service-tags-overview#available-service-tags
  regioncode_exceptions                = {
                                           "francecentral"      = "centralfrance"
                                           "francesouth"        = "southfrance"
                                           "germanynorth"       = "germanyn"
                                           "germanywestcentral" = "germanywc"
                                           "norwayeast"         = "norwaye"
                                           "norwaywest"         = "norwayw"
                                           "southcentralus"     = "usstagee"
                                           "southcentralusstg"  = "usstagec"
                                           "switzerlandnorth"   = "switzerlandn"
                                           "switzerlandwest"    = "switzerlandw"
                                         }

  firewall_service_tags                = format("AzureCloud.%s", lookup(local.regioncode_exceptions, var.infrastructure.region, var.infrastructure.region))

  // Bastion subnet
  management_bastion_subnet_arm_id     = try(var.infrastructure.vnets.management.subnet_bastion.arm_id, "")
  bastion_subnet_exists                = length(local.management_bastion_subnet_arm_id) > 0
  bastion_subnet_name                  = "AzureBastionSubnet"
  bastion_subnet_prefix                = local.bastion_subnet_exists ? (
                                           "") : (
                                           try(var.infrastructure.vnets.management.subnet_bastion.prefix, "")
                                         )

  // Webapp subnet
  webapp_subnet_arm_id                 = try(var.infrastructure.vnets.management.subnet_webapp.arm_id, "")
  webapp_subnet_exists                 = length(local.webapp_subnet_arm_id) > 0
  webapp_subnet_name                   = "AzureWebappSubnet"
  webapp_subnet_prefix                 = local.webapp_subnet_exists ? "" : try(var.infrastructure.vnets.management.subnet_webapp.prefix, "")

  enable_password                      = try(var.deployer.authentication.type, "key") == "password"
  enable_key                           = !local.enable_password

  username                             = try(var.authentication.username, "azureadm")

  // By default use generated password. Provide password under authentication overides it
  password                             = local.enable_password ? (
                                           coalesce(var.authentication.password, random_password.deployer[0].result)
                                           ) : (
                                           ""
                                         )

  // By default use generated public key. Provide authentication.path_to_public_key and path_to_private_key overrides it

  public_key                           = local.enable_key ? (
                                           var.bootstrap ?
                                              try(file(var.authentication.path_to_public_key), tls_private_key.deployer[0].public_key_openssh) :
                                              data.azurerm_key_vault_secret.stored_pk[0].value ) : (
                                           null)

  private_key                          = local.enable_key ? (
                                           var.bootstrap ?
                                             try(file(var.authentication.path_to_private_key), tls_private_key.deployer[0].private_key_pem)  :
                                              data.azurerm_key_vault_secret.stored_pkk[0].value ) : (
                                           null )

  // If the user specifies arm id of key vaults in input, the key vault will be imported instead of creating new key vaults

  automation_keyvault_exist            = var.key_vault.exists

  private_key_secret_name              = coalesce(
                                           var.key_vault.private_key_secret_name,
                                           replace(
                                             format("%s-sshkey",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                             )),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )
  public_key_secret_name               = coalesce(
                                           var.key_vault.public_key_secret_name,
                                           replace(
                                             format("%s-sshkey-pub",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                             ),
                                             "/[^A-Za-z0-9-]/",
                                             ""
                                           )
                                         )
  pwd_secret_name                      = coalesce(var.key_vault.password_secret_name,
                                           replace(
                                             format("%s-password",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                             ),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )
  username_secret_name                 = coalesce(var.key_vault.username_secret_name,
                                           replace(
                                             format("%s-username",
                                               length(local.prefix) > 0 ? (
                                                 local.prefix) : (
                                                 var.infrastructure.environment
                                               ),
                                             ),
                                             "/[^A-Za-z0-9-]/"
                                           , "")
                                         )

  // Extract information from the specified key vault arm ids
  user_keyvault_name                   = var.key_vault.exists ? split("/", var.key_vault.id)[8] : local.keyvault_names.user_access

  // Tags
  tags                                 = merge(var.infrastructure.tags,try(var.deployer.tags, { "Role" = "Deployer" }))



  parsed_id                            = try(provider::azurerm::parse_resource_id(var.infrastructure.application_configuration_id), "")
  app_config_name                      = length(var.infrastructure.application_configuration_id) > 0 ? local.parsed_id["resource_name"] : ""
  app_config_resource_group_name       = length(var.infrastructure.application_configuration_id) > 0 ? local.parsed_id["resource_group_name"] : ""

}

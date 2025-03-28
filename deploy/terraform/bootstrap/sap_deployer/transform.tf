# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


locals {

  infrastructure =                  {
    environment                        = coalesce(
                                          var.environment,
                                          try(var.infrastructure.environment, "")
                                          )
    region                             = coalesce(var.location, try(var.infrastructure.region, ""))
    codename                           = try(var.codename, try(var.infrastructure.codename, ""))
    resource_group                     = {
                                            name = try(
                                              coalesce(
                                                var.resourcegroup_name,
                                                try(var.infrastructure.resource_group.name, "")
                                              ),
                                              ""
                                            )
                                            arm_id = try(
                                              coalesce(
                                                var.resourcegroup_arm_id,
                                                try(var.infrastructure.resource_group.arm_id, "")
                                              ),
                                              ""
                                            )
                                          }
    tags                               = merge(
                                            var.tags, var.resourcegroup_tags
                                        )

    vnets                              = {
                                            management = {
                                              name = try(
                                                coalesce(
                                                  var.management_network_name,
                                                  try(var.infrastructure.vnets.management.name, "")
                                                ),
                                                ""
                                              )
                                              arm_id = try(
                                                coalesce(
                                                  var.management_network_arm_id,
                                                  try(var.infrastructure.vnets.management.arm_id, "")
                                                ),
                                                ""
                                              )
                                              address_space = try(
                                                coalesce(
                                                  var.management_network_address_space,
                                                  try(var.infrastructure.vnets.management.address_space, "")
                                                ),
                                                ""
                                              )
                                              flow_timeout_in_minutes=var.network_flow_timeout_in_minutes

                                              subnet_mgmt = {
                                                name = try(
                                                  coalesce(
                                                    var.management_subnet_name,
                                                    try(var.infrastructure.vnets.management.subnet_mgmt.name, "")
                                                  ),
                                                  ""
                                                )
                                                arm_id = try(
                                                  coalesce(
                                                    var.management_subnet_arm_id,
                                                    try(var.infrastructure.vnets.management.subnet_mgmt.arm_id, "")
                                                  ),
                                                  ""
                                                )
                                                prefix = try(
                                                  coalesce(
                                                    var.management_subnet_address_prefix,
                                                    try(var.infrastructure.vnets.management.subnet_mgmt.prefix, "")
                                                  ),
                                                  ""
                                                )
                                                nsg = {
                                                  name = try(
                                                    coalesce(
                                                      var.management_subnet_nsg_name,
                                                      try(var.infrastructure.vnets.management.nsg_mgmt.name, "")
                                                    ),
                                                    ""
                                                  )
                                                  arm_id = try(
                                                    coalesce(
                                                      var.management_subnet_nsg_arm_id,
                                                      try(var.infrastructure.vnets.management.nsg_mgmt.arm_id, "")
                                                    ),
                                                    ""
                                                  )
                                                  allowed_ips = try(
                                                    coalesce(
                                                      var.management_subnet_nsg_allowed_ips,
                                                      try(var.management_subnet_nsg_arm_id, "")
                                                    ),
                                                    []
                                                  )
                                                }
                                              }
                                              subnet_fw = {
                                                arm_id = try(
                                                  coalesce(
                                                    var.management_firewall_subnet_arm_id,
                                                    try(var.infrastructure.vnets.management.subnet_fw.arm_id, "")
                                                  ),
                                                  ""
                                                )
                                                prefix = try(
                                                  coalesce(
                                                    var.management_firewall_subnet_address_prefix,
                                                    try(var.infrastructure.vnets.management.subnet_fw.prefix, "")
                                                  ),
                                                  ""
                                                )
                                              }
                                              subnet_bastion = {
                                                arm_id = var.management_bastion_subnet_arm_id
                                                prefix = var.management_bastion_subnet_address_prefix
                                              }
                                              subnet_webapp = {
                                                arm_id = var.webapp_subnet_arm_id
                                                prefix = var.webapp_subnet_address_prefix
                                              }
                                            }
                                          }
    deploy_monitoring_extension        = var.deploy_monitoring_extension
    deploy_defender_extension          = var.deploy_defender_extension

    custom_random_id                   = var.custom_random_id
    bastion_public_ip_tags             = try(var.bastion_public_ip_tags, {})

    application_configuration_deployment = var.application_configuration_deployment
    application_configuration_id     = var.application_configuration_id

                                        }

  deployer                             = {
                                           size = try(
                                             coalesce(
                                               var.deployer_size,
                                               try(var.deployers[0].size, "")
                                             ),
                                             "Standard_D4ds_v4"
                                           )
                                           disk_type = coalesce(
                                             var.deployer_disk_type,
                                             try(var.deployers[0].disk_type, "")
                                           )
                                           use_DHCP = var.deployer_use_DHCP || try(var.deployers[0].use_DHCP, false)
                                           authentication = {
                                             type = coalesce(
                                               var.deployer_authentication_type,
                                               try(var.deployers[0].authentication.type, "")
                                             )
                                           }
                                           add_system_assigned_identity = var.add_system_assigned_identity
                                           os = {
                                                   os_type         = "LINUX"
                                                   type            = try(var.deployer_image.type, "marketplace")
                                                   source_image_id = try(coalesce(
                                                                       var.deployer_image.source_image_id,
                                                                       try(var.deployers[0].os.source_image_id, "")
                                                                       ),
                                                                       ""
                                                                     )
                                                   publisher       = try(coalesce(
                                                                       var.deployer_image.publisher,
                                                                       try(var.deployers[0].os.publisher, "")
                                                                     ), "")
                                                   offer           = try(coalesce(
                                                                       var.deployer_image.offer,
                                                                       try(var.deployers[0].os.offer, "")
                                                                     ), "")
                                                   sku             = try(coalesce(
                                                                       var.deployer_image.sku,
                                                                       try(var.deployers[0].os.sku, "")
                                                                     ), "")
                                                   version         = try(coalesce(
                                                                       var.deployer_image.version,
                                                                       try(var.deployers[0].sku, "")
                                                                     ), "")
                                                 }

                                           private_ip_address = try(coalesce(
                                                                  var.deployer_private_ip_address,
                                                                  try(var.deployers[0].private_ip_address, "")
                                                                ), "")

                                           deployer_diagnostics_account_arm_id = var.deployer_diagnostics_account_arm_id
                                           app_service_SKU                     = var.app_service_SKU_name
                                           user_assigned_identity_id           = var.user_assigned_identity_id
                                           shared_access_key_enabled           = true
                                           devops_authentication_type          = var.app_service_devops_authentication_type
                                           encryption_at_host_enabled          = var.encryption_at_host_enabled
                                           deployer_public_ip_tags             = try(var.deployer_public_ip_tags, {})


                                         }

  authentication                       = {
                                            username            = var.deployer_authentication_username
                                            password            = var.deployer_authentication_password
                                            path_to_public_key  = var.deployer_authentication_path_to_public_key
                                            path_to_private_key = var.deployer_authentication_path_to_private_key

                                          }
  key_vault                            = {
                                           id                        = var.user_keyvault_id
                                           exists                    = length(var.user_keyvault_id) > 0 ? true : false
                                           private_key_secret_name   = var.deployer_private_key_secret_name
                                           public_key_secret_name    = var.deployer_public_key_secret_name
                                           username_secret_name      = var.deployer_username_secret_name
                                           password_secret_name      = var.deployer_password_secret_name
                                           enable_rbac_authorization = var.enable_rbac_authorization_for_keyvault

                                        }
  options                              = {
                                            enable_deployer_public_ip = var.deployer_enable_public_ip || try(var.options.enable_deployer_public_ip, false)
                                            use_spn                   = var.use_spn
                                         }

  firewall                             = {
                                           deployment           = var.firewall_deployment
                                           rule_subnets         = var.firewall_rule_subnets
                                           allowed_ipaddresses  = var.firewall_allowed_ipaddresses
                                           ip_tags              = try(var.firewall_public_ip_tags, {})
                                         }


  app_service                          = {
                                           use                 = var.app_service_deployment
                                           app_registration_id = var.app_registration_app_id
                                           client_secret       = var.webapp_client_secret
                                         }

  dns_settings                         = {
                                           use_custom_dns_a_registration                = var.use_custom_dns_a_registration
                                           register_storage_accounts_keyvaults_with_dns = var.register_storage_accounts_keyvaults_with_dns
                                           register_endpoints_with_dns                  = var.register_endpoints_with_dns
                                           dns_zone_names                               = var.dns_zone_names

                                           local_dns_resourcegroup_name                 = ""

                                           management_dns_resourcegroup_name            = trimspace(var.management_dns_resourcegroup_name)
                                           management_dns_subscription_id               = var.management_dns_subscription_id

                                           privatelink_dns_subscription_id              = var.privatelink_dns_subscription_id != var.management_dns_subscription_id ? var.privatelink_dns_subscription_id : var.management_dns_subscription_id
                                           privatelink_dns_resourcegroup_name           = var.management_dns_resourcegroup_name != var.privatelink_dns_resourcegroup_name ? var.privatelink_dns_resourcegroup_name : var.management_dns_resourcegroup_name

                                         }

}

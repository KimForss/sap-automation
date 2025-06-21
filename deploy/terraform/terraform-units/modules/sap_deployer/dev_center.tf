resource "azurerm_dev_center" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = lower(format("%s%s%s%s",
                                                    var.naming.resource_prefixes.dev_center,
                                                    var.infrastructure.environment,
                                                    var.naming.resource_suffixes.dev_center,
                                                    coalesce(try(var.infrastructure.custom_random_id, ""), substr(random_id.deployer.hex, 0, 3)))
                                                  )
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  identity                                {
                                            type         = var.deployer.add_system_assigned_identity ? "SystemAssigned, UserAssigned" : "UserAssigned"
                                            identity_ids = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
                                          }
}

resource "azurerm_dev_center_project" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = upper(var.infrastructure.environment)
  dev_center_id                                 = azurerm_dev_center.deployer[0].id
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location

  identity                                {
                                            type         = var.deployer.add_system_assigned_identity ? "SystemAssigned, UserAssigned" : "UserAssigned"
                                            identity_ids = [length(var.deployer.user_assigned_identity_id) == 0 ? azurerm_user_assigned_identity.deployer[0].id : data.azurerm_user_assigned_identity.deployer[0].id ]
                                          }
}

resource "azurerm_dev_center_network_connection" "deployer" {
  name                                          = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                                    data.azurerm_subnet.subnet_mgmt[0].name) : (
                                                    azurerm_subnet.subnet_mgmt[0].name
                                                  )
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
  domain_join_type                              = "AzureADJoin"
  subnet_id                                     = var.infrastructure.virtual_network.management.subnet_mgmt.exists ? (
                                                    data.azurerm_subnet.subnet_mgmt[0].id) : (
                                                    azurerm_subnet.subnet_mgmt[0].id
                                                  )

}


resource "azurerm_dev_center_attached_network" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = upper(var.infrastructure.environment)
  dev_center_id                                 = azurerm_dev_center.deployer[0].id
  network_connection_id                         = azurerm_dev_center_network_connection.deployer[0].id
}

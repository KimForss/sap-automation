resource "azurerm_dev_center" "deployer" {
  count                                         = var.infrastructure.dev_center_deployment ? 1 : 0
  name                                          = lower(format("%s%s%s%s",
                                                    var.naming.resource_prefixes.dev_center,
                                                    var.naming.prefix.DEPLOYER,
                                                    var.naming.resource_suffixes.dev_center,
                                                    coalesce(try(var.infrastructure.custom_random_id, ""), substr(random_id.deployer.hex, 0, 3)))
                                                  )
  resource_group_name                           = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].name : azurerm_resource_group.deployer[0].name
  location                                      = var.infrastructure.resource_group.exists ? data.azurerm_resource_group.deployer[0].location : azurerm_resource_group.deployer[0].location
}

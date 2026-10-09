
// Creates endpoint subnet
resource "azurerm_subnet" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_endpoint.defined ? 1 : 0
  name                                 = local.endpoint_subnet_name
  resource_group_name                  = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].resource_group_name : azurerm_virtual_network.vnet_sap[0].resource_group_name
  virtual_network_name                 = var.infrastructure.virtual_networks.sap.exists ? data.azurerm_virtual_network.vnet_sap[0].name : azurerm_virtual_network.vnet_sap[0].name
  address_prefixes                     = [var.infrastructure.virtual_networks.sap.subnet_endpoint.prefix]

  private_endpoint_network_policies    = var.private_endpoint_network_policies

  service_endpoints                    = var.use_service_endpoint ? (
                                           ["Microsoft.Storage", "Microsoft.KeyVault"]
                                           ) : (
                                           null
                                         )
}

data "azurerm_subnet" "endpoint" {
  provider                             = azurerm.main
  count                                = var.infrastructure.virtual_networks.sap.subnet_endpoint.exists ? 1 : 0
  name                                 = split("/", var.infrastructure.virtual_networks.sap.subnet_endpoint.id)[10]
  resource_group_name                  = split("/", var.infrastructure.virtual_networks.sap.subnet_endpoint.id)[4]
  virtual_network_name                 = split("/", var.infrastructure.virtual_networks.sap.subnet_endpoint.id)[8]
}


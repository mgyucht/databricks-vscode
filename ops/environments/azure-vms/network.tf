resource "azurerm_virtual_network" "this" {
  name                = "${local.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = azurerm_resource_group.this.tags
}

resource "azurerm_subnet" "this" {
  name                 = "${local.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "this" {
  name                = "${local.prefix}-sg"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = azurerm_resource_group.this.tags
}

module "zscaler" {
  source = "../../modules/zscaler"
}

resource "azurerm_network_security_rule" "zscaler" {
  for_each  = module.zscaler.ranges
  name      = "Zscaler: ${each.key}"
  priority  = each.value.priority
  direction = "Inbound"
  access    = "Allow"
  protocol  = "Tcp"

  source_port_range          = "*"
  destination_port_range     = "3389"
  source_address_prefixes    = each.value.prefixes
  destination_address_prefix = "*"

  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

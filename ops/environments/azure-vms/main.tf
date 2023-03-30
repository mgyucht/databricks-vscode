locals {
  prefix = "eng-dev-ecosystem-vms"
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = "West Europe"
  tags = {
    "Owner" = "eng-dev-ecosystem-team@databricks.com"
  }
}

module "vm" {
  source = "../../modules/azure-vm"

  for_each = toset(module.defaults.admins)
  prefix   = "deco-vm-${split("@", each.key)[0]}"
  username = split("@", each.key)[0]

  resource_group_name       = azurerm_resource_group.this.name
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

output "details" {
  sensitive = true
  value = {
    for username, vm in module.vm : username => {
      url      = "https://portal.azure.com/#@dbtestcustomer.onmicrosoft.com/resource/subscriptions/${module.defaults.azure_production_sub}/resourceGroups/${azurerm_resource_group.this.name}/providers/Microsoft.Compute/virtualMachines/${vm.name}/overview"
      username = vm.username
      password = vm.password
    }
  }
}

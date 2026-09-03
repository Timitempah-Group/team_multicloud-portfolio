# Random admin password -- required by the VM resource even though we
# never log in with it; all interaction happens via Run Command instead
resource "random_password" "vm_admin" {
  length  = 20
  special = true
}

# NSG: allow inbound ICMP only from AWS's address range
resource "azurerm_network_security_group" "test" {
  name                = "nsg-multicloud-test"
  location            = "uksouth"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name

  security_rule {
    name                       = "AllowICMPFromAWS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = data.terraform_remote_state.phase1.outputs.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

resource "azurerm_network_interface" "test" {
  name                = "nic-multicloud-test"
  location            = "uksouth"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.terraform_remote_state.phase1.outputs.azure_workload_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "test" {
  network_interface_id     = azurerm_network_interface.test.id
  network_security_group_id = azurerm_network_security_group.test.id
}

# The temporary test VM -- no public IP, reached only via Azure Run Command
# (az vm run-command invoke), which executes through Azure's control plane
resource "azurerm_linux_virtual_machine" "test" {
  name                = "vm-multicloud-test"
  resource_group_name = data.terraform_remote_state.phase1.outputs.azure_resource_group_name
  location            = "uksouth"
  size                = "Standard_D2ns_v6" # B-series unavailable for this subscription in uksouth; confirmed via az vm list-skus
  admin_username      = "azureuser"
  admin_password      = random_password.vm_admin.result
  disable_password_authentication = false

  network_interface_ids = [azurerm_network_interface.test.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Project = "multicloud-portfolio"
    Task    = "01-cross-cloud-foundations"
  }
}

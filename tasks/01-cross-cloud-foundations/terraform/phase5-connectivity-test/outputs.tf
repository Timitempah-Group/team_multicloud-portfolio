output "aws_test_instance_id" {
  value = aws_instance.test.id
}

output "aws_test_instance_private_ip" {
  value = aws_instance.test.private_ip
}

output "azure_test_vm_name" {
  value = azurerm_linux_virtual_machine.test.name
}

output "azure_test_vm_private_ip" {
  value = azurerm_network_interface.test.private_ip_address
}

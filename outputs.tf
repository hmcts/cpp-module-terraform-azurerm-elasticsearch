output "data_cloud_init_config" {
  value = data.template_cloudinit_config.data-config
}

output "es_host_master_ip_config" {
  value = azurerm_network_interface.primary-master-nic[*].ip_configuration[*]
}

output "es_host_master_private_ip" {
  value = azurerm_network_interface.primary-master-nic[*].ip_configuration[*].private_ip_address
}

output "es_host_data_ip_config" {
  value = azurerm_network_interface.primary-data-nic[*].ip_configuration[*]
}

output "es_host_data_private_ip" {
  value = azurerm_network_interface.primary-data-nic[*].ip_configuration[*].private_ip_address
}

output "master_cloud_init_config" {
  value = data.template_cloudinit_config.master-config
}

output "es_lb_private_ip" {
  value = azurerm_lb.master-host-lb.private_ip_address

}

data "template_file" "master-cloud-init" {
  template = file("${path.module}/template/master-cloud-init")
  vars = {
    es_cluster                  = var.es_cluster
    http_port                   = var.http_port
    transport_port              = var.transport_port
    priv_dns_zone               = var.priv_dns_zone
    master_host_prefix          = var.master_host_prefix
    data_host_prefix            = var.data_host_prefix
    security_enabled            = false
    monitoring_enabled          = false
    security_enrollment_enabled = false
    master                      = true
    data                        = false
    master_count                = var.master_count
    data_count                  = var.data_count
    elasticsearch_logs_dir      = var.elasticsearch_logs_dir
    elasticsearch_data_dir      = var.elasticsearch_data_dir
  }
}

data "template_cloudinit_config" "master-config" {
  gzip          = false
  base64_encode = true

  # Main cloud-init configuration file.
  part {
    filename     = "master-cloud-init"
    content_type = "text/cloud-config"
    content      = data.template_file.master-cloud-init.rendered
  }
}

# SUBNET
data "azurerm_subnet" "master-subnet1" {
  name                 = var.es_subnet
  virtual_network_name = var.es_vnet
  resource_group_name  = var.es_rg
}

data "azurerm_virtual_network" "es-vnet" {
  name                = var.es_vnet
  resource_group_name = var.es_rg
}

resource "azurerm_network_interface" "primary-master-nic" {
  count               = var.master_count
  name                = "${var.master_host_prefix}-nic${count.index}"
  location            = var.location
  resource_group_name = var.es_rg

  ip_configuration {
    name                          = "es-primary-interface"
    subnet_id                     = data.azurerm_subnet.master-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "es-master-az-set" {
  name                         = "es-master-az-set"
  location                     = var.location
  resource_group_name          = var.es_rg
  platform_fault_domain_count  = var.platform_fault_domain_count
  platform_update_domain_count = var.platform_update_domain_count
  managed                      = true
}

resource "azurerm_linux_virtual_machine" "es-master-host" {
  count               = var.master_count
  name                = "${var.master_host_prefix}-${count.index}"
  resource_group_name = var.es_rg
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.primary-master-nic[count.index].id
  ]

  custom_data = data.template_cloudinit_config.master-config.rendered
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_user_pub_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_id = var.source_image_id
}

resource "azurerm_managed_disk" "master-disk1" {
  count                = var.master_count
  name                 = "${var.master_host_prefix}-lun0-${count.index}"
  location             = var.location
  resource_group_name  = var.es_rg
  storage_account_type = var.master_nodes_storage_class
  create_option        = "Empty"
  disk_size_gb         = var.master_node_disk1_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "master-disk-attach" {
  count              = var.master_count
  managed_disk_id    = azurerm_managed_disk.master-disk1[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.es-master-host[count.index].id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_snapshot" "master-disk1-snapshot" {
  count               = var.master_count
  name                = "${var.master_host_prefix}-snapshot-lun0-${count.index}"
  location            = var.location
  resource_group_name = var.es_rg
  create_option       = "Copy"
  source_uri          = azurerm_managed_disk.master-disk1[count.index].id
}

resource "azurerm_private_dns_a_record" "master-records" {
  count               = var.master_count
  name                = lower("${azurerm_linux_virtual_machine.es-master-host[count.index].name}")
  resource_group_name = var.dns_zone_rg
  zone_name           = var.priv_dns_zone
  ttl                 = 300
  records             = ["${azurerm_network_interface.primary-master-nic[count.index].private_ip_address}"]
}

resource "azurerm_lb" "master-host-lb" {
  name                = "es-master-host-lb"
  location            = var.location
  resource_group_name = var.es_rg
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "es-master-lb-ip"
    subnet_id                     = data.azurerm_subnet.master-subnet1.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Dynamic"

  }
}

resource "azurerm_lb_backend_address_pool" "master-es-lb-pool" {
  loadbalancer_id = azurerm_lb.master-host-lb.id
  name            = "InternalESLBPool"
}

resource "azurerm_lb_backend_address_pool_address" "master_hosts" {
  count                   = var.master_count
  name                    = "master_host_${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.master-es-lb-pool.id
  virtual_network_id      = data.azurerm_virtual_network.es-vnet.id
  ip_address              = azurerm_network_interface.primary-master-nic[count.index].ip_configuration[0].private_ip_address
}

resource "azurerm_lb_probe" "es-probe" {
  name            = "es-lb-probe"
  loadbalancer_id = azurerm_lb.master-host-lb.id
  port            = 9200
}

resource "azurerm_lb_rule" "es-master-rules" {
  loadbalancer_id                = azurerm_lb.master-host-lb.id
  name                           = "ESLBRule"
  protocol                       = "Tcp"
  frontend_port                  = 9200
  backend_port                   = 9200
  frontend_ip_configuration_name = "es-master-lb-ip"
  backend_address_pool_ids       = ["${azurerm_lb_backend_address_pool.master-es-lb-pool.id}"]
  probe_id                       = azurerm_lb_probe.es-probe.id
}

resource "azurerm_private_dns_a_record" "es-master-lb" {
  name                = lower("${azurerm_lb.master-host-lb.name}")
  resource_group_name = var.dns_zone_rg
  zone_name           = var.priv_dns_zone
  ttl                 = 300
  records             = ["${azurerm_lb.master-host-lb.private_ip_address}"]
}

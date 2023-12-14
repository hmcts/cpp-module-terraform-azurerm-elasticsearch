data "template_file" "data-cloud-init" {
  template = file("${path.module}/template/data-cloud-init")
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
    master                      = false
    data                        = true
    master_count                = var.master_count
    data_count                  = var.data_count
    elasticsearch_logs_dir      = var.elasticsearch_logs_dir
    elasticsearch_data_dir      = var.elasticsearch_data_dir
  }
}

data "template_cloudinit_config" "data-config" {
  gzip          = false
  base64_encode = true

  # Main cloud-init configuration file.
  part {
    filename     = "data-cloud-init"
    content_type = "text/cloud-config"
    content      = data.template_file.data-cloud-init.rendered
  }
}

# SUBNET
data "azurerm_subnet" "data-subnet1" {
  name                 = var.es_subnet
  virtual_network_name = var.es_vnet
  resource_group_name  = var.es_rg
}

resource "azurerm_network_interface" "primary-data-nic" {
  count               = var.data_count
  name                = "${var.data_host_prefix}-nic${count.index}"
  location            = var.location
  resource_group_name = var.es_rg

  ip_configuration {
    name                          = "es-primary-interface"
    subnet_id                     = data.azurerm_subnet.data-subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_availability_set" "es-data-az-set" {
  name                         = "es-data-az-set"
  location                     = var.location
  resource_group_name          = var.es_rg
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_linux_virtual_machine" "es-data-host" {
  count               = var.data_count
  name                = "${var.data_host_prefix}-${count.index}"
  resource_group_name = var.es_rg
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.primary-data-nic[count.index].id
  ]

  custom_data = data.template_cloudinit_config.data-config.rendered
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

resource "azurerm_managed_disk" "data-disk1" {
  count                = var.data_count
  name                 = "${var.data_host_prefix}-lun0-${count.index}"
  location             = var.location
  resource_group_name  = var.es_rg
  storage_account_type = var.data_nodes_storage_class
  create_option        = "Empty"
  disk_size_gb         = var.data_node_disk1_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk-attach" {
  count              = var.data_count
  managed_disk_id    = azurerm_managed_disk.data-disk1[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.es-data-host[count.index].id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_private_dns_a_record" "data-records" {
  count               = var.data_count
  name                = lower("${azurerm_linux_virtual_machine.es-data-host[count.index].name}")
  resource_group_name = var.dns_zone_rg
  zone_name           = var.priv_dns_zone
  ttl                 = 300
  records             = ["${azurerm_network_interface.primary-data-nic[count.index].private_ip_address}"]
}

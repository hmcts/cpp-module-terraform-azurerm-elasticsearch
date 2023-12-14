variable "admin_username" {
  type        = string
  description = "Elasticsearch cluster name"
}

variable "admin_user_pub_ssh_key" {
  type        = string
  description = "The public ssh key for admin user"
  default     = ""
}

variable "vm_size" {
  type        = string
  description = "Define the size /type of the virtual machine"
  default     = "Standard_DS1_v2"
}

variable "master_node_disk1_size" {
  type        = number
  description = "The disk size for external disk for master nodes"
  default     = 10
}

variable "data_node_disk1_size" {
  type        = number
  description = "The disk size for external disk for data nodes"
  default     = 10
}

variable "master_nodes_storage_class" {
  type        = string
  description = "The storage class for additional disk attached to master nodd"
  default     = "Standard_LRS"
}

variable "data_nodes_storage_class" {
  type        = string
  description = "The storage class for additional disk attached to data nodd"
  default     = "Standard_LRS"
}

variable "es_cluster" {
  type        = string
  description = "The name of Elastic search cluster"
}

variable "http_port" {
  type        = string
  description = "The http port for Elastic Search masters"
  default     = ""
}

variable "transport_port" {
  type        = string
  description = "The transport port for Elastic Search masters"
  default     = ""
}

variable "master_host_prefix" {
  type        = string
  description = "Elasticsearch master node prefix for hostname"
}

variable "data_host_prefix" {
  type        = string
  description = "Elasticsearch data node prefix for hostname"
}

variable "master_count" {
  type        = number
  description = "Numbe rof master nodes to provision"
  default     = 0
}

variable "data_count" {
  type        = number
  description = "Numbe rof data nodes to provision"
  default     = 0
}

variable "elasticsearch_logs_dir" {
  type        = string
  description = "Defines directory path where elasticsearch logs will be stored"
  default     = "/var/log/elasticsearch"
}

variable "elasticsearch_data_dir" {
  type        = string
  description = "Defines directory path where elasticsearch data and other valuable information will be stored"
  default     = "/var/data/elasticsearch"
}

variable "es_subnet" {
  type        = string
  description = "Subnet for Elasticsearch virtual machines"
}

variable "es_rg" {
  type        = string
  description = "Resource Group for Elasticsearch resources"
}

variable "es_vnet" {
  type        = string
  description = "Virtual Network for Elasticsearch resources"
}

variable "source_image_id" {
  type        = string
  description = "The image id of the source image"
}

# whether or not to enable x-pack security on the cluster
variable "security_enabled" {
  default = false
}

variable "monitoring_enabled" {
  default = false
}

variable "security_enrollment_enabled" {
  default = false
}

variable "location" {
  type        = string
  description = "Geo location where the resource to be deployed"
  default     = "uksouth"
}

variable "dns_zone_rg" {
  type        = string
  description = "The private dns zone Resource Group name"
}

variable "priv_dns_zone" {
  type        = string
  description = "The private dns zone name"
}

variable "platform_fault_domain_count" {
  type        = number
  description = "The number of fault domain count for the availability set - upto 3 as of today"
}

variable "platform_update_domain_count" {
  type        = number
  description = "The number of update domain counts for the availability set - upto 20 as of today"
}
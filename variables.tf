variable "prefix" {
  type        = string
  description = "The prefix for all your resources. Ex.: <prefix>-rg, <prefix>-vnet"
}

variable "environment_name" {
  type        = string
  description = "Environment Name."
  default     = "dev"
}

variable "location" {
  type        = string
  description = "The Azure region where your resources will be created."
}

variable "common_tags" {
    type = map(string)
    description = "Common resources tags. Key-value pair"
    default = {}
}

variable "vm_size" {
  type        = string
  description = "Use a VMSS instead of single VM."
  default     = "Standard_DS1_v2"
}

variable "vmss_instances" {
  type        = number
  description = "If using VMSS specified the number of instances for the VMSS. Default is 2."
  default     = 1
}

variable "vm_username" {
  type        = string
  description = "The username for the Azure VM."
}

variable "vm_password" {
  type        = string
  description = "The password for the Azure VM."
  default     = ""
}

variable "vm_image_id" {
  type        = string
  description = "The VM Image Id to use for the VM or VMSS."
  default     = ""
}

variable "vm_image_ref" {
  type        = map(string)
  description = "The VM Image Id to use for the VM or VMSS."
  default     = {}
}

variable "remote_port" {
  description = "Protocols to be used for remote vm access. [protocol, backend_port].  Frontend port will be automatically generated starting at 50000 and in the output."
  default     = {
    sql = ["Tcp", "1433"]
  }
}

variable "lb_port" {
  description = "Protocols to be used for lb health probes and rules. [frontend_port, protocol, backend_port]"
  default     = {
    sql = ["1433", "Tcp", "1433"]
  }
}

# SQL MI target variables

variable "sql_mi_fqdn" {
  type        = string
  description = "The FQDN of the backend SQL MI host"
}

variable "vnet_rg_name" {
  type        = string
  description = "The Azure Resource Group where the Virtual Network exists."
}

variable "vnet_name" {
  type        = string
  description = "The Azure Virtual Network where target resource exists."
}
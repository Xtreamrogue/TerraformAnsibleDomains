# vSphere Credentials
variable "vsphere_user" {
  description = "The username for connecting to the vSphere environment."
  type        = string
}

variable "vsphere_password" {
  description = "The password for connecting to the vSphere environment."
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "The vSphere server address."
  type        = string
}

# Datacenter Configuration
variable "datacenter" {
  description = "The name of the vSphere datacenter."
  type        = string
}

variable "datastore" {
  description = "The name of the datastore to use for the virtual machines."
  type        = string
}

variable "cluster" {
  description = "The name of the compute cluster to use."
  type        = string
}

# Network and Template
variable "template" {
  description = "The name of the VM template to use."
  type        = string
}

# VM Configuration Variables
variable "admin_password" {
  description = "The administrator password for the Windows VMs."
  type        = string
  sensitive   = true
}

variable "networks" {
  type = map(object({
    network_name    = string
    gateway         = string
    domain          = string
    dns_server_list = list(string)
  }))
  description = "A map of networks to their configurations."

  default = {
    "network_1" = {
      network_name    = "VM Network"                          #Replace with VMWare Network
      gateway         = "192.168.0.1"                   #Replace Gateway IP 
      domain          = "Domain Name"                 #Replace with Domain Name
      dns_server_list = ["20.20.20.200", "20.20.20.1"] #Replace with DNS Servers
    },
    "network_2" = {
      network_name    = "VM Netwrok 2"                          #Replace with VMWare Network
      gateway         = "192.168.1.1"                   #Replace Gateway IP 
      domain          = "Second Domain Name"                 #Replace with Domain Name
      dns_server_list = ["30.30.30.200", "30.30.30.1"] #Replace with DNS Servers
    }
  }
}

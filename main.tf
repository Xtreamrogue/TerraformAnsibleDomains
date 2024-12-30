###############################################################################
# Terraform Configuration Block
###############################################################################
terraform {
  # Lock in the vsphere provider version (example version ~> 2.2)
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.2"
    }
  }

  # Specify the minimum Terraform version you wish to use
  required_version = ">= 1.0.0"
}

###############################################################################
# Provider Configuration
###############################################################################
# For security, do NOT store credentials in this file directly.
# Instead, set them as environment variables or in a *.tfvars file.
provider "vsphere" {
  user                 = var.vsphere_user       # e.g., "administrator@vsphere.local"
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server     # e.g., "vcenter.example.com"
  allow_unverified_ssl = true                   # Set to false in production if you have valid SSL
}

###############################################################################
# Data Sources - Retrieve existing objects from vSphere
###############################################################################
# Retrieves the Datacenter
data "vsphere_datacenter" "dc" {
  name = "Lab"  # Replace with your actual Datacenter Name
}

# Retrieves datastore(s). Adjust if you only need one datastore.
data "vsphere_datastore" "ds1" {
  name          = "nvme1"  # Replace with your Datastore Name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds2" {
  name          = "nvme2"  # Replace with your Datastore Name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieves the Compute Cluster
data "vsphere_compute_cluster" "cluster" {
  name          = "home"   # Replace with your Cluster Name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Example: Retrieve multiple networks dynamically via for_each
# var.networks should be a map/object. For example:
# networks = {
#   "network_1" = { network_name = "VM Network" },
#   "network_2" = { network_name = "DMZ Network" }
# }
data "vsphere_network" "all" {
  for_each      = var.networks
  name          = each.value.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieves a Windows VM template from vSphere
data "vsphere_virtual_machine" "template" {
  name          = "Win2022-Template-Base"  # Replace with your actual template name
  datacenter_id = data.vsphere_datacenter.dc.id
}

###############################################################################
# Resource - Create/Clone Virtual Machines
###############################################################################
# local.vms should be a map of VM definitions. For example:
# local.vms = {
#   "myvm1" = {
#     datastore_key = "ds1"
#     network_key   = "network_1"
#     num_cpus      = 2
#     memory        = 2048
#     ip_address    = "192.168.100.10"
#     dns_servers   = ["192.168.100.1"]
#     gateway       = "192.168.100.1"
#   },
#   "myvm2" = {
#     datastore_key = "ds2"
#     network_key   = "network_2"
#     ...
#   }
# }
resource "vsphere_virtual_machine" "vm" {
  for_each = local.vms

  # The VM name in vSphere
  name             = each.key

  # Attach to a Resource Pool (the cluster's default resource pool, in this example)
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id

  # Place .vmx and related files on the specified datastore
  datastore_id = local.datastores[each.value.datastore_key]

  # Hardware configuration
  num_cpus = each.value.num_cpus
  memory   = each.value.memory
  guest_id = data.vsphere_virtual_machine.template.guest_id
  firmware = "efi"

  # Network configuration - use the matched network from data source
  network_interface {
    network_id   = data.vsphere_network.all[each.value.network_key].id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  # Storage / Disk configuration
  # IMPORTANT: If your template disk label is "Hard disk 1", update "disk0" to "Hard disk 1".
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    datastore_id     = local.datastores[each.value.datastore_key]
    eagerly_scrub    = false
    thin_provisioned = true
  }

  # Clone from template and customize
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      windows_options {
        computer_name    = each.key
        admin_password   = var.admin_password
        workgroup        = "WORKGROUP"
        auto_logon       = true
        auto_logon_count = 1

        # Example of commands to enable WinRM for Ansible, etc.
        run_once_command_list = [
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command Set-Item -Path WSMan:\\localhost\\Service\\AllowUnencrypted -Value true",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command Set-Item -Path WSMan:\\localhost\\Service\\Auth\\Basic -Value true",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command Enable-PSRemoting -Force",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command winrm quickconfig -quiet",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command winrm set winrm/config/service @{AllowUnencrypted='true'}",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command winrm set winrm/config/service/auth @{Basic='true'}",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command Remove-Item -Path WSMan:\\localhost\\Listener -Recurse",
          "cmd.exe /C powershell.exe -ExecutionPolicy Bypass -Command New-Item -Path WSMan:\\localhost\\Listener -Transport HTTP -Address * -Port 5985 -Force"
        ]
      }

      # Network interface customization
      network_interface {
        ipv4_address    = each.value.ip_address
        ipv4_netmask    = 24
        dns_server_list = each.value.dns_servers
      }

      # Default IPv4 gateway
      ipv4_gateway = each.value.gateway
    }
  }
}

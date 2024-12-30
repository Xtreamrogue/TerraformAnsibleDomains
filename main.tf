provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "Lab"
}

data "vsphere_datastore" "ds1" {
  name          = "nvme1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds2" {
  name          = "nvme2"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "home"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Example networks from variable "var.networks"
# var.networks might look like:
# {
#   "network_1" = { network_name = "VM Network" },
#   "network_2" = { network_name = "DMZ Network" }
# }
data "vsphere_network" "all" {
  for_each     = var.networks
  name         = each.value.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "Win2022-Template-Base"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  for_each = local.vms

  name             = each.key
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id

  # This sets where the VM configuration files go (.vmx, etc.)
  datastore_id = local.datastores[each.value.datastore_key]

  num_cpus = each.value.num_cpus
  memory   = each.value.memory
  guest_id = data.vsphere_virtual_machine.template.guest_id
  firmware = "efi"

  network_interface {
    network_id   = data.vsphere_network.all[each.value.network_key].id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  # ---- IMPORTANT ----
  # If your template disk label is "Hard disk 1", replace "disk0" with "Hard disk 1".
  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    # Point the cloned disk to the correct datastore:
    datastore_id     = local.datastores[each.value.datastore_key]
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      windows_options {
        computer_name    = each.key
        admin_password   = var.admin_password
        workgroup        = "WORKGROUP"
        auto_logon       = true
        auto_logon_count = 1
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

      network_interface {
        ipv4_address    = each.value.ip_address
        ipv4_netmask    = 24
        dns_server_list = each.value.dns_servers
      }

      ipv4_gateway = each.value.gateway
    }
  }

  # Example: local provisioner to run an Ansible playbook
  provisioner "local-exec" {
    command = <<EOT
      sleep 30
      ansible-playbook -i /home/xtream/domains/ansible/inventory /home/xtream/domains/ansible/domains.yml \
        --extra-vars "ansible_user=Administrator ansible_password=${var.admin_password} ansible_connection=winrm ansible_winrm_server_cert_validation=ignore ansible_port=5985" -vvv | tee /tmp/ansible-debug.log
    EOT
  }
}

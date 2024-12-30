locals {
  # Define VMs and their configurations in one place
  vms = {
    # Example: VM1
    NUBRXDC01 = {
      network_key   = "network_1"
      ip_address    = "20.20.20.200"
      num_cpus      = 2
      memory        = 4096
      gateway       = "20.20.20.1"
      dns_servers   = ["20.20.20.200", "20.20.20.1"]
      datastore_key = "ds1" # Maps to datastore nvme1
    },
    # Example: VM2
    NUCTADC01 = {
      network_key   = "network_2"
      ip_address    = "30.30.30.200"
      num_cpus      = 2
      memory        = 4096
      gateway       = "30.30.30.1"
      dns_servers   = ["30.30.30.200", "30.30.30.1"]
      datastore_key = "ds2" # Maps to datastore nvme2
    },
  }

  # Map datastore keys to actual datastore IDs
  datastores = {
    ds1 = data.vsphere_datastore.ds1.id
    ds2 = data.vsphere_datastore.ds2.id
  }
}

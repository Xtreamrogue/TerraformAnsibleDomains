###############################################################################
# locals.tf
###############################################################################
locals {
  vms = {
    # -------------------------------------------------------------------------
    # Example VM1
    # -------------------------------------------------------------------------
    BUCDC01 = {
      network_key   = "network_1"
      ip_address    = "20.20.20.200"                  #Replace IP Address of 1st Domain Controler
      num_cpus      = 2                               #Replace CPU of the VM
      memory        = 4096                            #Replace RAM of the VM
      gateway       = "20.20.20.1"                    #Replace  Gateway IP Address
      dns_servers   = ["20.20.20.200", "20.20.20.1"]  #Replace DNS of the 1st Domain Controler
      datastore_key = "ds1"                           #Maps to datastore "nvme1"
    },

    # -------------------------------------------------------------------------
    # Example VM2
    # -------------------------------------------------------------------------
    CTADC01 = {
      network_key   = "network_2"
      ip_address    = "30.30.30.200"                      #Replace IP Address of 2nd Domain Controler
      num_cpus      = 2                                   #Replace CPU of the VM
      memory        = 4096                                #Replace RAM of the VM
      gateway       = "30.30.30.1"                        #Replace  Gateway IP Address
      dns_servers   = ["30.30.30.200", "30.30.30.1"]      #Replace DNS of the 2nd Domain Controler
      datastore_key = "ds2"                               #Maps to datastore "nvme2"
    },
  }

  datastores = {
    ds1 = data.vsphere_datastore.ds1.id
    ds2 = data.vsphere_datastore.ds2.id
  }
}

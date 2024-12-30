# VMware vSphere + Windows AD Deployment

This repository provides an **Infrastructure as Code** approach to:
1. **Provision Windows VMs** in VMware vSphere (using **Terraform**).
2. **Configure Windows Server** as an Active Directory Domain Controller (using **Ansible**).

By following these instructions, anyone cloning this repository can adapt the files to their own environment with minimal effort.

---

## Table of Contents
1. [Overview](#overview)  
2. [Prerequisites](#prerequisites)  
3. [Repository Structure](#repository-structure)  
4. [Configuration Steps](#configuration-steps)  
   1. [Set up Terraform Variables](#1-set-up-terraform-variables)  
   2. [Customize Locals (VM Definitions)](#2-customize-locals-vm-definitions)  
   3. [Configure Ansible Group Vars](#3-configure-ansible-group-vars)  
   4. [Run Terraform](#4-run-terraform)  
   5. [Run Ansible (If Needed)](#5-run-ansible-if-needed)  
5. [Security Considerations](#security-considerations)  
6. [Troubleshooting](#troubleshooting)  
7. [License](#license)

---

## Overview

- **Terraform**: Clones Windows Server Templates from VMware vSphere, customizing CPU, memory, network settings, and basic Windows configuration (WinRM, firewall rules, etc.).  
- **Ansible**: Performs post-deployment tasks (installing AD DS, promoting the server to a Domain Controller, creating OUs and service accounts).

### Key Components
- **main.tf** (Terraform): Defines the vSphere provider config, data sources, VM resources, and (optionally) a local-exec provisioner to run Ansible.  
- **locals.tf** (Terraform): Holds reusable local values like VM definitions and datastore mappings.  
- **group_vars/all.yml** (Ansible): Contains domain names, passwords, OU structure, and DNS settings.  
- **ad_setup.yml** (Ansible Playbook): Installs/configures AD Domain Services (example name).

---

## Prerequisites

1. **Terraform** >= 1.0.0  
2. **Ansible** >= 2.10 (with WinRM support and [pywinrm](https://pypi.org/project/pywinrm/) installed)  
3. **vSphere Account** with privileges to clone templates and create VMs.  
4. **Windows VM Template** in vSphere:
   - Sysprep-ready or generalizable  
   - Correct disk label (e.g., `"disk0"` or `"Hard disk 1"`)  
   - VMware Tools installed  
5. **(Optional) Ansible Vault** for securing passwords

---

## Repository Structure

├── main.tf # Main Terraform config for vSphere ├── locals.tf # Local variables for VM definitions & datastore mappings ├── variables.tf # (Optional) Definitions for Terraform variables ├── group_vars/ │ └── all.yml # Ansible variables (domain details, passwords, OUs, DNS) ├── ad_setup.yml # Example Ansible playbook for AD setup ├── .gitignore # Ignore Terraform state & sensitive files └── README.md # This file

yaml
Copy code

---

## Configuration Steps

### 1. Set up Terraform Variables

Terraform uses variables like `vsphere_user`, `vsphere_password`, `vsphere_server`, and `admin_password`. For security, **do not** store credentials in `main.tf` directly.

- **Create `variables.tf`** (if not present) to define variables:
  ```hcl
  variable "vsphere_user" {}
  variable "vsphere_password" {
    sensitive = true
  }
  variable "vsphere_server" {}
  variable "admin_password" {
    sensitive = true
  }
Provide these variables via one of:
Environment variables (e.g., TF_VAR_vsphere_user)
Terraform variables file (e.g., terraform.tfvars, which is not committed to Git)
2. Customize Locals (VM Definitions)
locals.tf contains:

local.vms – A map of VMs to create, each with its own IP, network, CPU, memory, etc.
local.datastores – Maps a short datastore key (like ds1) to the actual data.vsphere_datastore.ds1.id from main.tf.
Example (simplified):

hcl
Copy code
locals {
  vms = {
    MyDomainController01 = {
      network_key   = "network_1"
      ip_address    = "192.168.10.10"
      num_cpus      = 2
      memory        = 4096
      gateway       = "192.168.10.1"
      dns_servers   = ["192.168.10.1"]
      datastore_key = "ds1"
    }
  }

  datastores = {
    ds1 = data.vsphere_datastore.ds1.id
    ds2 = data.vsphere_datastore.ds2.id
  }
}
Adjust values according to your environment (IP addresses, gateways, datastore keys, etc.).

3. Configure Ansible Group Vars
Edit group_vars/all.yml to set your domain info, OU structure, and DNS settings. For example:

yaml
Copy code
domain_name: "example.lab"
domain_netbios_name: "EXAMPLE"
domain_path: "DC=example,DC=lab"
domain_admin_password: "ChangeMe123!"
safe_mode_password: "ChangeMe123!"
upstream_dns_1: "8.8.8.8"
upstream_dns_2: "8.8.4.4"
root_ou: "MainOffice"
sub_ous:
  - "Service Accounts"
  - "Security Groups"
  - "Users"
  - "Servers"
  - "Workstations"
workstation_ous:
  - "Win10"
  - "Win11"
Note: Use Ansible Vault or another secret management tool for real passwords.

4. Run Terraform
Initialize:
bash
Copy code
terraform init
Validate:
bash
Copy code
terraform validate
Plan:
bash
Copy code
terraform plan
Apply:
bash
Copy code
terraform apply
If your Terraform config includes a local-exec provisioner to run Ansible, it will be triggered automatically after the VMs are created.
5. Run Ansible (If Needed)
If Terraform does not automatically invoke Ansible (or if you prefer manual control), run:

bash
Copy code
ansible-playbook -i <your_inventory> ad_setup.yml \
  --extra-vars "ansible_user=Administrator ansible_password=<VM Administrator Password> \
                ansible_connection=winrm ansible_winrm_server_cert_validation=ignore \
                ansible_port=5985"
Ensure the host(s) in your inventory match the IP addresses of the newly created VMs.
Update ansible_user / ansible_password if needed to match your local admin credentials.
Security Considerations
Never commit real passwords or *.tfstate files to a public repository.
Use a .gitignore to exclude:
*.tfstate, *.tfvars, *.tfstate.backup, etc.
Store credentials in:
Ansible Vault, or
Environment variables, or
A secure external secrets manager.
If running in CI/CD, make sure secrets are stored securely (e.g., GitHub Actions Secrets).
Troubleshooting
Terraform Issues

Verify references to datastore IDs, network IDs, or variable references in your .tf files.
Check vCenter user permissions to clone templates and create VMs.
Ansible WinRM Connection

Verify WinRM is open on port 5985 in your Windows template.
Confirm firewall rules are allowing WinRM.
AD DS Promotion Failures

Inspect logs on Windows (C:\Windows\debug\Dcpromo.log or C:\Windows\NTDS) for domain promotion errors.
Verify your domain admin/safe mode passwords meet complexity requirements.
License
Licensed under the MIT License (or replace with your chosen license). See the LICENSE file for details.

Happy Automating! If you run into any issues or have enhancements, please open an issue or submit a pull request.

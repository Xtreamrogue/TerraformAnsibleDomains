# TerraformAnsibleDomains
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

1. Provide these variables via one of:
Environment variables (e.g., TF_VAR_vsphere_user)
Terraform variables file ( terraform.tfvars)
2. Customize Locals (VM Definitions)
locals.tf contains:
local.vms – A map of VMs to create, each with its own IP, network, CPU, memory, etc.
local.datastores – Maps a short datastore key (like ds1) to the actual data.vsphere_datastore.ds1.id from main.tf.
3. Configure Ansible Group Vars.
   Edit Main.yml for each DC to set your domain info, OU structure, and DNS settings
    |--Ansible
         |--roles
           |--DC01
             |--vars
                |--Main.yml
4. Run Terraform



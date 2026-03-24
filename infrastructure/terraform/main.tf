###############################################################################
# Terraform - Provisioning de 3 VMs sur Proxmox (1 Master + 2 Workers)
# Les VMs sont placées dans un sous-réseau privé avec accès Internet via NAT
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_user             = var.proxmox_user
  pm_password         = var.proxmox_password
  pm_tls_insecure     = true
  pm_parallel         = 2
  pm_timeout          = 600
}

###############################################################################
# Réseau - Configuration du bridge et sous-réseau privé
# Les VMs utilisent un réseau privé (10.10.10.0/24) avec NAT pour Internet
###############################################################################

# Cloud-init template doit être préparé sur Proxmox au préalable
# Voir instructions dans le README

###############################################################################
# VM Master Node - Control Plane Kubernetes
###############################################################################
resource "proxmox_vm_qemu" "k8s_master" {
  name        = var.master_name
  target_node = var.proxmox_node
  clone       = var.template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.master_cores
  sockets     = 1
  cpu_type    = "host"
  memory      = var.master_memory
  scsihw      = "virtio-scsi-single"
  bootdisk    = "scsi0"
  onboot      = true

  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.master_disk_size
          storage = var.storage_pool
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_tag
  }

  # Cloud-init configuration
  ipconfig0  = "ip=${var.master_ip}/${var.subnet_mask},gw=${var.gateway_ip}"
  nameserver = var.dns_servers
  ciuser     = var.vm_user
  sshkeys    = var.ssh_public_key

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  tags = "kubernetes,master"
}

###############################################################################
# VM Worker Nodes - Kubernetes Workers
###############################################################################
resource "proxmox_vm_qemu" "k8s_workers" {
  count       = var.worker_count
  name        = "${var.worker_name_prefix}-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.worker_cores
  sockets     = 1
  cpu_type    = "host"
  memory      = var.worker_memory
  scsihw      = "virtio-scsi-single"
  bootdisk    = "scsi0"
  onboot      = true

  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.worker_disk_size
          storage = var.storage_pool
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.vlan_tag
  }

  # Cloud-init configuration
  ipconfig0  = "ip=${var.worker_ips[count.index]}/${var.subnet_mask},gw=${var.gateway_ip}"
  nameserver = var.dns_servers
  ciuser     = var.vm_user
  sshkeys    = var.ssh_public_key

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  tags = "kubernetes,worker"
}


###############################################################################
# Outputs Terraform - Informations sur les VMs créées
###############################################################################

output "master_ip" {
  description = "Adresse IP du noeud master Kubernetes"
  value       = var.master_ip
}

output "worker_ips" {
  description = "Adresses IP des noeuds workers Kubernetes"
  value       = var.worker_ips
}

output "master_name" {
  description = "Nom de la VM master"
  value       = proxmox_vm_qemu.k8s_master.name
}

output "worker_names" {
  description = "Noms des VMs workers"
  value       = [for w in proxmox_vm_qemu.k8s_workers : w.name]
}

output "ssh_user" {
  description = "Utilisateur SSH pour se connecter aux VMs"
  value       = var.vm_user
}

output "domain" {
  description = "Domaine de l'application"
  value       = var.domain
}

output "ssh_commands" {
  description = "Commandes SSH pour se connecter aux VMs (via jump host Proxmox)"
  value = join("\n", concat(
    [
      "# ============================================================",
      "# Les VMs sont sur un réseau PRIVÉ (10.10.10.0/24)",
      "# → Impossible d'y accéder directement depuis votre machine",
      "# → Il faut passer par Proxmox comme 'jump host' (rebond SSH)",
      "# ============================================================",
      "",
      "# Master :",
      "ssh -i ~/.ssh/proxmox_key -J root@${var.proxmox_host} ${var.vm_user}@${var.master_ip}",
      "",
    ],
    [for i, ip in var.worker_ips :
      "# Worker-${i + 1} :\nssh -i ~/.ssh/proxmox_key -J root@${var.proxmox_host} ${var.vm_user}@${ip}\n"
    ]
  ))
}

# Génération automatique de l'inventaire Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_ip    = var.master_ip
    worker_ips   = var.worker_ips
    ssh_user     = var.vm_user
    proxmox_host = var.proxmox_host
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
}

resource "local_file" "ansible_vars" {
  content = templatefile("${path.module}/templates/ansible_vars.tpl", {
    master_ip   = var.master_ip
    worker_ips  = var.worker_ips
    domain      = var.domain
    acme_email  = var.acme_email
  })
  filename = "${path.module}/../ansible/group_vars/all.yml"
}

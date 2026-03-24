###############################################################################
# terraform.tfvars - Variables à personnaliser pour votre environnement
# IMPORTANT: Ne commitez JAMAIS ce fichier dans Git (ajoutez-le dans .gitignore)
###############################################################################

# ---- Connexion Proxmox ----
proxmox_api_url  = "https://51.158.200.50:8006/api2/json"
proxmox_user     = "root@pam"
proxmox_password = "63lSy$vo2SLx"
proxmox_node     = "pve"

# ---- Template VM (cloud-init) ----
template_name = "ubuntu-2204-cloud"
storage_pool  = "local-lvm"

# ---- Réseau ----
network_bridge = "vmbr0"
vlan_tag       = -1
subnet_mask    = "24"
gateway_ip     = "10.10.10.1"
dns_servers    = "8.8.8.8 8.8.4.4"

# ---- Utilisateur VM ----
vm_user        = "k8sadmin"
ssh_public_key = "ssh-rsa AAAA... votre-cle-publique-ici"

# ---- Master Node ----
master_name      = "k8s-master"
master_ip        = "10.10.10.10"
master_cores     = 4
master_memory    = 4096
master_disk_size = "50G"

# ---- Worker Nodes ----
worker_count       = 2
worker_name_prefix = "k8s-worker"
worker_ips         = ["10.10.10.11", "10.10.10.12"]
worker_cores       = 4
worker_memory      = 4096
worker_disk_size   = "50G"

# ---- Application / Domaine ----
# Remplacez par votre domaine réel configuré dans Cloud DNS
domain     = "example.com"
acme_email = "admin@example.com"


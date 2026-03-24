###############################################################################
# Variables Terraform pour le déploiement Proxmox
###############################################################################

# ---- Proxmox Connection ----
variable "proxmox_api_url" {
  description = "URL de l'API Proxmox (ex: https://192.168.1.1:8006/api2/json)"
  type        = string
}

variable "proxmox_host" {
  description = "IP ou hostname du serveur Proxmox (pour le jump SSH vers les VMs)"
  type        = string
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox pour l'API (ex: root@pam)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Mot de passe Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nom du noeud Proxmox cible"
  type        = string
  default     = "pve"
}

# ---- Template VM ----
variable "template_name" {
  description = "Nom du template cloud-init à cloner (ex: ubuntu-2204-cloud)"
  type        = string
  default     = "ubuntu-2204-cloud"
}

variable "storage_pool" {
  description = "Pool de stockage Proxmox (ex: local-lvm, ceph, zfs)"
  type        = string
  default     = "local-lvm"
}

# ---- Réseau ----
variable "network_bridge" {
  description = "Bridge réseau Proxmox (ex: vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "Tag VLAN pour isoler le sous-réseau privé (-1 = pas de VLAN)"
  type        = number
  default     = -1
}

variable "subnet_mask" {
  description = "Masque de sous-réseau en notation CIDR (ex: 24)"
  type        = string
  default     = "24"
}

variable "gateway_ip" {
  description = "Adresse IP de la passerelle pour accès Internet"
  type        = string
  default     = "10.10.10.1"
}

variable "dns_servers" {
  description = "Serveurs DNS (séparés par des espaces)"
  type        = string
  default     = "8.8.8.8 8.8.4.4"
}

# ---- VM User ----
variable "vm_user" {
  description = "Utilisateur créé par cloud-init sur les VMs"
  type        = string
  default     = "k8sadmin"
}

variable "ssh_public_key" {
  description = "Clé SSH publique pour l'accès aux VMs"
  type        = string
}

# ---- Master Node ----
variable "master_vmid" {
  description = "ID Proxmox de la VM master (doit être unique, ex: 110)"
  type        = number
  default     = 110
}

variable "master_name" {
  description = "Nom de la VM master"
  type        = string
  default     = "k8s-master"
}

variable "master_ip" {
  description = "Adresse IP du noeud master"
  type        = string
  default     = "10.10.10.10"
}

variable "master_cores" {
  description = "Nombre de cores CPU pour le master"
  type        = number
  default     = 4
}

variable "master_memory" {
  description = "Mémoire RAM (Mo) pour le master"
  type        = number
  default     = 4096
}

variable "master_disk_size" {
  description = "Taille du disque du master (ex: 50G)"
  type        = string
  default     = "50G"
}

# ---- Worker Nodes ----
variable "worker_vmid_start" {
  description = "ID Proxmox de départ pour les workers (worker-1=111, worker-2=112, etc.)"
  type        = number
  default     = 111
}

variable "worker_count" {
  description = "Nombre de noeuds worker"
  type        = number
  default     = 2
}

variable "worker_name_prefix" {
  description = "Préfixe du nom des VMs worker"
  type        = string
  default     = "k8s-worker"
}

variable "worker_ips" {
  description = "Liste des IPs pour les workers"
  type        = list(string)
  default     = ["10.10.10.11", "10.10.10.12"]
}

variable "worker_cores" {
  description = "Nombre de cores CPU pour chaque worker"
  type        = number
  default     = 4
}

variable "worker_memory" {
  description = "Mémoire RAM (Mo) pour chaque worker"
  type        = number
  default     = 4096
}

variable "worker_disk_size" {
  description = "Taille du disque de chaque worker (ex: 50G)"
  type        = string
  default     = "50G"
}

# ---- Application / Domain ----
variable "domain" {
  description = "Nom de domaine principal de l'application (ex: myapp.example.com)"
  type        = string
}

variable "acme_email" {
  description = "Email pour Let's Encrypt (certificats TLS)"
  type        = string
}

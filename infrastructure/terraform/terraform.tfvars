###############################################################################
# terraform.tfvars - Variables à personnaliser pour votre environnement
# IMPORTANT: Ne commitez JAMAIS ce fichier dans Git (ajoutez-le dans .gitignore)
###############################################################################

# ---- Connexion Proxmox ----
proxmox_api_url  = "https://51.158.200.50:8006/api2/json"
proxmox_user     = "root@pam"
proxmox_password = "63lSy$vo2SLx"
# IP publique du serveur Proxmox (utilisée comme jump host pour accéder aux VMs privées en SSH)
proxmox_host     = "51.158.200.50"
# ⚠️ Le nom du nœud Proxmox = le hostname du serveur Proxmox.
# Ce n'est PAS l'adresse IP, c'est le NOM affiché dans l'interface web Proxmox.
#
# Comment le trouver ? 2 méthodes :
#
#   Méthode 1 (SSH) : Connectez-vous en SSH au serveur Proxmox et tapez :
#     hostname
#     → Exemple de résultat : sd-178488
#
#   Méthode 2 (Interface Web) : Allez sur https://IP_PROXMOX:8006
#     → Dans le panneau de gauche, sous "Datacenter", le nom du nœud est affiché
#     → Exemple : Datacenter → sd-178488
#
#   Méthode 3 (API) : Sur le serveur Proxmox, tapez :
#     pvesh get /nodes --output-format json
#     → Cherchez le champ "node" dans la sortie
#
# Par défaut, Proxmox utilise "pve" comme nom de nœud, mais ce nom peut
# varier selon l'hébergeur ou la configuration. Remplacez la valeur ci-dessous
# par le résultat de la commande "hostname" de votre serveur Proxmox.
proxmox_node     = "sd-178488"

# ---- Template VM (cloud-init) ----
template_name = "ubuntu-2204-cloud"
storage_pool  = "vmdata"

# ---- Réseau ----
# ⚠️ Les VMs utilisent des IPs privées 10.10.10.x → elles doivent être sur vmbr1
# (le bridge privé avec NAT configuré dans /etc/network/interfaces)
# vmbr0 = bridge PUBLIC (IP publique du serveur Proxmox) → PAS pour les VMs privées
# vmbr1 = bridge PRIVÉ (10.10.10.1/24 + NAT vers Internet) → pour les VMs
network_bridge = "vmbr1"
vlan_tag       = -1
subnet_mask    = "24"
gateway_ip     = "10.10.10.1"
dns_servers    = "8.8.8.8 8.8.4.4"

# ---- Utilisateur VM ----
vm_user        = "k8sadmin"
# ⚠️ Ici c'est la CLÉ PUBLIQUE (fichier .pub), PAS la clé privée !
# Récupérez-la avec : cat ~/.ssh/proxmox_key.pub
# Format attendu : une seule ligne commençant par ssh-ed25519 ou ssh-rsa
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOFjV7nUn/uucp/MreZ4PppiJyZuA0jzDt8qJm6/0AjH nzapa@nzapa-HP-EliteBook-840-G3"

# ---- Master Node ----
# vmid = identifiant unique de la VM dans Proxmox
# On fixe les IDs pour éviter les conflits avec des VMs existantes
# Vérifiez les IDs déjà utilisés avec : qm list (sur le serveur Proxmox)
master_vmid      = 110
master_name      = "k8s-master"
master_ip        = "10.10.10.10"
master_cores     = 4
master_memory    = 4096
master_disk_size = "50G"

# ---- Worker Nodes ----
# worker_vmid_start = ID de départ pour les workers
# Worker-1 aura l'ID 111, Worker-2 l'ID 112, etc.
worker_vmid_start  = 111
worker_count       = 2
worker_name_prefix = "k8s-worker"
worker_ips         = ["10.10.10.11", "10.10.10.12"]
worker_cores       = 4
worker_memory      = 4096
worker_disk_size   = "50G"

# ---- Application / Domaine ----
# Remplacez par votre domaine réel configuré dans Cloud DNS
domain     = "onlineboutique.ip-ddns.com"
acme_email = "nzapanarcisse@gmail.com"


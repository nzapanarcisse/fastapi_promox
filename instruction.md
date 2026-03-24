# ============================================================================
# INSTRUCTION.md - Guide Complet du Projet de Déploiement FastAPI sur Proxmox
# ============================================================================

## 📋 Contexte du Projet

Ce projet consiste à déployer une application **FastAPI Full-Stack** (backend Python + frontend React) sur un serveur **Proxmox** en utilisant une stack DevOps complète :

| Outil | Rôle |
|-------|------|
| **Terraform** | Provisioning de l'infrastructure (3 VMs sur Proxmox) |
| **Ansible** | Installation et configuration de Kubernetes + composants |
| **Kubernetes** | Orchestration des conteneurs |
| **Traefik v3** | Ingress Controller + Gateway API + TLS |
| **Cert-Manager** | Gestion automatique des certificats Let's Encrypt |
| **ArgoCD** | Déploiement GitOps continu |
| **Helm** | Packaging des manifests Kubernetes |
| **HPA** | Autoscaling horizontal (haute disponibilité) |
| **GitHub Actions** | Pipeline CI/CD complet |

---

## 🏗️ Architecture de l'Application

L'application est composée de :

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                  │
│                           │                                      │
│                    ┌──────▼──────┐                               │
│                    │   Traefik   │ (Ingress + TLS Let's Encrypt) │
│                    │    v3.2.1   │                               │
│                    └──────┬──────┘                               │
│              ┌────────────┼────────────┐                        │
│              ▼            ▼            ▼                        │
│   dashboard.DOMAIN   api.DOMAIN   adminer.DOMAIN               │
│      ┌────────┐     ┌────────┐    ┌────────┐                   │
│      │Frontend│     │Backend │    │Adminer │                    │
│      │React/  │     │FastAPI │    │DB Admin│                    │
│      │Nginx   │     │Python  │    │        │                    │
│      └────────┘     └───┬────┘    └───┬────┘                   │
│                         │             │                         │
│                    ┌────▼─────────────▼──┐                      │
│                    │    PostgreSQL 12     │                      │
│                    │   (Bitnami Helm)     │                      │
│                    └─────────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

### Sous-domaines requis (à configurer dans Cloud DNS)

| Sous-domaine | Service | Port |
|---|---|---|
| `api.DOMAIN` | Backend FastAPI | 8000 |
| `dashboard.DOMAIN` | Frontend React/Nginx | 80 |
| `adminer.DOMAIN` | Adminer (DB Admin) | 8080 |
| `argocd.DOMAIN` | ArgoCD Dashboard | 443 |
| `traefik.DOMAIN` | Traefik Dashboard | 443 |

---

## 🏢 Architecture Infrastructure

```
┌─────────────────────────────────────────────────────────┐
│                   Proxmox VE Server                      │
│                  51.158.200.50:8006                       │
│                                                          │
│   Sous-réseau privé : 10.10.10.0/24                     │
│   Gateway/NAT : 10.10.10.1 → Internet                   │
│                                                          │
│   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│   │ k8s-master   │ │ k8s-worker-1 │ │ k8s-worker-2 │   │
│   │ 10.10.10.10  │ │ 10.10.10.11  │ │ 10.10.10.12  │   │
│   │ 4 CPU/4Go RAM│ │ 4 CPU/4Go RAM│ │ 4 CPU/4Go RAM│   │
│   │ 50Go Disk    │ │ 50Go Disk    │ │ 50Go Disk    │   │
│   │              │ │              │ │              │     │
│   │ Control Plane│ │    Worker    │ │    Worker    │     │
│   │ + etcd       │ │              │ │              │     │
│   │ + API Server │ │              │ │              │     │
│   └──────────────┘ └──────────────┘ └──────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Structure des Fichiers d'Infrastructure

```
infrastructure/
├── terraform/                    # Provisioning VMs Proxmox
│   ├── main.tf                   # Ressources (3 VMs)
│   ├── variables.tf              # Déclaration des variables
│   ├── terraform.tfvars          # Valeurs des variables (NE PAS COMMITTER)
│   ├── outputs.tf                # Outputs + génération inventaire Ansible
│   └── templates/
│       ├── inventory.tpl         # Template inventaire Ansible
│       └── ansible_vars.tpl      # Template variables Ansible
│
├── ansible/                      # Configuration Kubernetes
│   ├── site.yml                  # Playbook principal
│   ├── inventory/                # (généré par Terraform)
│   │   └── hosts.ini
│   ├── group_vars/               # (généré par Terraform)
│   │   └── all.yml
│   └── roles/
│       ├── common/tasks/main.yml        # OS: updates, swap off, sysctl
│       ├── kubernetes/tasks/main.yml    # containerd + kubeadm/kubelet/kubectl
│       ├── master/tasks/main.yml        # kubeadm init + Flannel + Helm
│       ├── worker/tasks/main.yml        # kubeadm join
│       └── k8s-components/
│           ├── tasks/main.yml           # Traefik, Cert-Manager, ArgoCD, HPA
│           └── templates/
│               ├── traefik-values.yml.j2
│               ├── cluster-issuer.yml.j2
│               ├── cluster-issuer-staging.yml.j2
│               ├── argocd-values.yml.j2
│               └── default-hpa.yml.j2
│
├── helm/fastapi-app/             # Helm Chart de l'application
│   ├── Chart.yaml
│   ├── values.yaml               # Valeurs par défaut
│   ├── values-production.yaml    # Surcharge production
│   └── templates/
│       ├── _helpers.tpl
│       ├── secret.yaml
│       ├── configmap.yaml
│       ├── backend-deployment.yaml
│       ├── backend-service.yaml
│       ├── frontend-deployment.yaml
│       ├── frontend-service.yaml
│       ├── ingress.yaml
│       ├── prestart-job.yaml     # Migrations DB (Alembic)
│       ├── adminer.yaml
│       └── hpa.yaml              # Autoscaling horizontal
│
├── argocd/                       # Manifests ArgoCD (GitOps)
│   ├── application.yaml          # Application ArgoCD
│   └── project.yaml              # Projet ArgoCD
│
.github/workflows/
└── ci-cd.yml                     # Pipeline CI/CD complet

```

---

## 🔧 Prérequis

### Sur votre machine locale
- **Terraform** >= 1.5.0 → [Installation](https://developer.hashicorp.com/terraform/install)
- **Ansible** >= 2.15 → `pip install ansible`
- **kubectl** → [Installation](https://kubernetes.io/docs/tasks/tools/)
- **Helm** >= 3.0 → [Installation](https://helm.sh/docs/intro/install/)
- **Docker** → Pour builder les images
- **Une clé SSH** → `ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s_proxmox`

### Sur le serveur Proxmox
- **Un template cloud-init** Ubuntu 22.04 prêt à l'emploi
- **Un bridge réseau** (vmbr0 par défaut)
- **NAT configuré** pour que le sous-réseau privé accède à Internet

### Préparation du template cloud-init sur Proxmox

Connectez-vous en SSH au serveur Proxmox et exécutez :

#### 1. Identifier le pool de stockage disponible

Chaque installation Proxmox a des noms de stockage différents. Avant tout, identifiez le vôtre :

```bash
pvesm status
```

Exemple de sortie :
```
Name          Type     Status           Total            Used       Available        %
local          dir     active        53733704         6962500        44009272   12.96%
vmdata     zfspool     active      5653921792             564      5653921228    0.00%
```

> **⚠️ IMPORTANT** : Repérez le stockage de type `zfspool`, `lvmthin` ou `lvm` — c'est celui qui hébergera les disques des VMs.
> Dans les commandes ci-dessous, **remplacez `<STORAGE>` par le nom de votre stockage** (ex: `vmdata`, `local-lvm`, `local-zfs`, etc.)

#### 2. Créer le template

##### Pourquoi une image "cloud" et pas une ISO classique ?

| | Image ISO classique | Image Cloud |
|---|---|---|
| **Installation** | Manuelle (écran, clavier, clics, partitionnement...) | Aucune — le système est **pré-installé** |
| **Taille** | ~2 Go | ~600 Mo (légère) |
| **Cloud-init** | ❌ Absent | ✅ **Intégré** — c'est la clé de l'automatisation |
| **Automatisable** | ❌ Difficile | ✅ Conçue pour ça |
| **Cas d'usage** | Installation manuelle sur un PC | Déploiement automatisé (cloud, Terraform, etc.) |

**Cloud-init** est un outil embarqué dans l'image cloud qui, **au premier démarrage**, configure automatiquement :
- Le nom d'hôte (hostname)
- L'adresse IP et la gateway
- Les clés SSH autorisées
- L'utilisateur et son mot de passe
- Les paquets à installer, les scripts à exécuter, etc.

C'est grâce à cloud-init que **Terraform peut injecter la configuration réseau et SSH sans aucune intervention humaine**.

##### Pourquoi un template (et pas créer les VMs directement) ?

Un template est un **modèle en lecture seule** qu'on clone pour créer des VMs :

```
Template (ID 9000)  ──clone──►  VM k8s-master    (10.10.10.10)
  (créé 1 seule     ──clone──►  VM k8s-worker-1  (10.10.10.11)
   fois)             ──clone──►  VM k8s-worker-2  (10.10.10.12)
```

Sans template, il faudrait installer Ubuntu manuellement sur chaque VM.
Avec le template, Terraform clone en quelques secondes et cloud-init personnalise chaque VM.

##### Commandes

```bash
# ============================================================================
# ÉTAPE 2a : TÉLÉCHARGER L'IMAGE CLOUD UBUNTU
# ============================================================================
# On se place dans le dossier où Proxmox stocke les images ISO et templates
# C'est le chemin standard de Proxmox pour ce type de fichier
cd /var/lib/vz/template/iso/

# On télécharge l'image cloud d'Ubuntu 22.04 LTS (nom de code "Jammy Jellyfish")
# - "cloud" = image pré-installée avec cloud-init intégré
# - "amd64" = architecture processeur 64 bits (la plus courante)
# - C'est un fichier .img (image disque), PAS un .iso (installateur)
# - Taille : ~600 Mo vs ~2 Go pour une ISO classique
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# ============================================================================
# ÉTAPE 2b : CRÉER UNE VM VIDE (la "coquille")
# ============================================================================
# qm = "QEMU Manager" — l'outil en ligne de commande de Proxmox pour gérer les VMs
# create 9000 = crée une VM avec l'ID 9000
#   → On utilise 9000 par convention pour les templates (IDs élevés = templates)
#   → Les VMs réelles utiliseront des IDs plus bas (100, 101, 102...)
#
# --name ubuntu-2204-cloud = nom lisible dans l'interface Proxmox
# --memory 2048 = 2 Go de RAM (valeur par défaut, sera modifiée par Terraform au clonage)
# --cores 2 = 2 cœurs CPU (idem, modifiable par Terraform)
# --net0 virtio,bridge=vmbr0 = une carte réseau virtuelle :
#   → "virtio" = pilote réseau paravirtualisé (le plus performant en VM)
#   → "bridge=vmbr0" = connectée au bridge principal de Proxmox
#
# ⚠️ À ce stade, la VM est VIDE — pas de disque, pas d'OS. C'est juste une "boîte".
qm create 9000 --name ubuntu-2204-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# ============================================================================
# ÉTAPE 2c : IMPORTER LE DISQUE (mettre Ubuntu dans la VM)
# ============================================================================
# Cette commande prend l'image .img téléchargée et la convertit en disque virtuel
# exploitable par Proxmox, puis la stocke dans le pool de stockage.
#
# → Remplacez <STORAGE> par le nom trouvé avec "pvesm status" (ex: vmdata, local-lvm)
#
# Analogie : c'est comme installer un disque dur SSD (avec Ubuntu pré-installé)
#            dans un ordinateur vide.
#
# ⚠️ À ce stade le disque est importé mais PAS ENCORE BRANCHÉ à la VM
qm importdisk 9000 jammy-server-cloudimg-amd64.img <STORAGE>

# ============================================================================
# ÉTAPE 2d : BRANCHER LE DISQUE À LA VM
# ============================================================================
# --scsihw virtio-scsi-pci = utilise le contrôleur de disque VirtIO SCSI
#   → C'est le contrôleur le plus performant pour la virtualisation
#   → Meilleur que IDE ou SATA en termes de débit et latence
#
# --scsi0 <STORAGE>:vm-9000-disk-0 = branche le disque importé sur le port SCSI 0
#   → "scsi0" = premier emplacement de disque
#   → "vm-9000-disk-0" = nom du disque créé automatiquement lors de l'import
#
# Analogie : on branche le câble entre la carte mère et le disque dur.
#            Maintenant la VM peut démarrer depuis ce disque.
qm set 9000 --scsihw virtio-scsi-pci --scsi0 <STORAGE>:vm-9000-disk-0

# ============================================================================
# ÉTAPE 2e : AJOUTER LE DISQUE CLOUD-INIT
# ============================================================================
# Cette commande crée un PETIT disque virtuel spécial dédié à cloud-init.
# Ce disque ne contient PAS l'OS, il contient uniquement les PARAMÈTRES de config :
#   - Hostname, IP, gateway, DNS
#   - Clés SSH autorisées
#   - Utilisateur à créer
#   - Scripts à exécuter au premier démarrage
#
# Fonctionnement :
# ┌─────────────────┐     ┌──────────────────┐
# │ Disque Ubuntu   │     │ Disque Cloud-Init│
# │ (scsi0)         │     │ (ide2)           │
# │                 │     │                  │
# │ Le système      │◄────│ hostname: k8s-1  │
# │ Ubuntu démarre  │ lit │ ip: 10.10.10.10  │
# │ et lit les      │     │ ssh_key: xxx     │
# │ paramètres      │     │ user: k8sadmin   │
# └─────────────────┘     └──────────────────┘
#
# C'est Terraform qui écrira les valeurs dans ce disque au moment du clonage.
# → ide2 = emplacement IDE secondaire (convention Proxmox pour cloud-init)
qm set 9000 --ide2 <STORAGE>:cloudinit

# ============================================================================
# ÉTAPE 2f : CONFIGURER LE DÉMARRAGE
# ============================================================================
# --boot c = boot depuis le disque dur ("c" = HDD, comme dans un BIOS)
#   → Pas de boot réseau (PXE), pas de boot CD/DVD
# --bootdisk scsi0 = le disque de démarrage est celui branché à l'étape 2d
#
# Analogie : dans le BIOS, on sélectionne "Démarrer depuis le disque dur"
qm set 9000 --boot c --bootdisk scsi0

# ============================================================================
# ÉTAPE 2g : CONFIGURER LA CONSOLE SÉRIE
# ============================================================================
# Les images cloud n'ont PAS d'interface graphique (pas de bureau, pas d'écran).
# Elles sont conçues pour être utilisées uniquement en SSH.
#
# --serial0 socket = ajoute un port série virtuel (comme un câble série RS-232)
# --vga serial0 = redirige l'affichage vers ce port série
#
# Pourquoi ? Cela permet d'avoir une console TEXTE dans l'interface web Proxmox
# (bouton "Console" → "xterm.js"). Très utile pour le debug si SSH ne marche pas.
# Sans ça, l'écran de la VM dans Proxmox resterait noir.
qm set 9000 --serial0 socket --vga serial0

# ============================================================================
# ÉTAPE 2h : ACTIVER L'AGENT QEMU
# ============================================================================
# L'agent QEMU (qemu-guest-agent) est un petit programme qui tourne DANS la VM
# et communique avec l'hyperviseur Proxmox.
#
# Il permet à Proxmox (et donc à Terraform) de :
#   ✅ Connaître la VRAIE adresse IP de la VM (pas juste celle configurée)
#   ✅ Savoir quand la VM a fini de démarrer
#   ✅ Exécuter des commandes dans la VM (freeze/thaw pour les snapshots)
#   ✅ Arrêter proprement la VM (shutdown graceful)
#
# ⚠️ IMPORTANT pour Terraform : sans l'agent, Terraform ne peut pas vérifier
# que la VM est prête après le clonage → il échoue ou attend indéfiniment.
#
# Note : l'agent est déjà pré-installé dans les images cloud Ubuntu.
# Cette commande dit juste à Proxmox "attends-toi à ce que l'agent soit disponible".
qm set 9000 --agent enabled=1

# ============================================================================
# ÉTAPE 2i : CONVERTIR EN TEMPLATE (verrouiller le modèle)
# ============================================================================
# Cette commande transforme la VM 9000 en TEMPLATE :
#   🔒 Elle n'est PLUS démarrable directement
#   🔒 Elle n'est PLUS modifiable
#   🔒 Elle est en LECTURE SEULE
#   ✅ Elle est prête à être CLONÉE autant de fois que nécessaire
#
# Analogie : comme mettre un document Word en "lecture seule".
#            On ne peut plus le modifier, mais on peut en faire des copies.
#
# Après cette commande, dans l'interface Proxmox, l'icône de la VM change
# pour indiquer que c'est un template (icône avec un petit document).
qm template 9000
```

> **Exemple concret** : Si `pvesm status` affiche `vmdata` comme stockage ZFS, les commandes deviennent :
> ```bash
> qm importdisk 9000 jammy-server-cloudimg-amd64.img vmdata
> qm set 9000 --scsihw virtio-scsi-pci --scsi0 vmdata:vm-9000-disk-0
> qm set 9000 --ide2 vmdata:cloudinit
> ```

##### Récapitulatif visuel

```
ÉTAPE 2a : wget image cloud ──────────────┐ (télécharger Ubuntu)
                                           ▼
ÉTAPE 2b : qm create 9000 ──► VM vide     │ (créer la boîte)
                                │          │
ÉTAPE 2c : qm importdisk ──────┘  disque ◄┘ (mettre l'OS dans le stockage)
                                               
ÉTAPE 2d : qm set scsi0  ──► branche le disque Ubuntu à la VM
ÉTAPE 2e : qm set ide2   ──► ajoute le disque cloud-init (paramètres)
ÉTAPE 2f : qm set boot   ──► configure le démarrage sur le bon disque
ÉTAPE 2g : qm set serial ──► ajoute une console texte (debug)
ÉTAPE 2h : qm set agent  ──► active la communication VM ↔ Proxmox
                                               
ÉTAPE 2i : qm template   ──► 🔒 VERROUILLÉ = TEMPLATE PRÊT
                                     │
                            Terraform clone ici
                              ┌──────┼──────┐
                              ▼      ▼      ▼
                           Master  Worker1  Worker2
```

### Configuration du NAT sur Proxmox (accès Internet pour le sous-réseau privé)

#### Pourquoi un bridge privé (vmbr1) ?

Par défaut, Proxmox dispose d'un seul bridge `vmbr0` connecté directement à Internet avec l'IP publique du serveur (51.158.200.50). Le problème :

```
SANS bridge privé (vmbr0 seul) :
┌──────────────────────────────────────────────┐
│  Proxmox (vmbr0 = IP publique)               │
│                                               │
│   VM1 (IP publique ?)  ← Il faudrait une     │
│   VM2 (IP publique ?)  ← IP publique par VM  │
│   VM3 (IP publique ?)  ← = coûteux + exposé  │
└──────────────────────────────────────────────┘
❌ Problèmes :
   - Il faudrait acheter 3 IPs publiques supplémentaires
   - Chaque VM est directement exposée sur Internet (risque sécurité)
   - Pas de réseau privé entre les VMs
```

```
AVEC bridge privé (vmbr1) :
┌──────────────────────────────────────────────────────┐
│  Proxmox                                              │
│  vmbr0 (51.158.200.50) ← seul point d'entrée public │
│       │                                               │
│       │ NAT (translation d'adresses)                  │
│       │                                               │
│  vmbr1 (10.10.10.1/24) ← réseau privé isolé         │
│       │                                               │
│   ┌───┴────┬───────────┬───────────┐                 │
│   │ Master │ Worker-1  │ Worker-2  │                 │
│   │ .10    │ .11       │ .12       │                 │
│   └────────┴───────────┴───────────┘                 │
└──────────────────────────────────────────────────────┘
✅ Avantages :
   - 1 seule IP publique suffit (le serveur Proxmox)
   - Les VMs communiquent entre elles sur le réseau privé (rapide)
   - Les VMs ne sont PAS directement exposées sur Internet (sécurité)
   - Le NAT permet aux VMs d'accéder à Internet (pour apt, docker pull, etc.)
   - C'est exactement comme votre box Internet à la maison (192.168.x.x)
```

#### Comment configurer

Sur le serveur Proxmox, éditez le fichier `/etc/network/interfaces` :

```bash
nano /etc/network/interfaces
```

Ajoutez le bloc suivant **à la fin du fichier** :

```bash
# ============================================================================
# BRIDGE PRIVÉ vmbr1 - Réseau interne pour les VMs Kubernetes
# ============================================================================
# Ce bridge crée un réseau local isolé (comme un switch virtuel)
# Les VMs y seront connectées avec des IPs privées 10.10.10.x
# Proxmox sert de routeur/gateway pour donner Internet aux VMs via NAT

auto vmbr1
iface vmbr1 inet static

    # L'IP du bridge = la gateway pour les VMs
    # Les VMs utiliseront 10.10.10.1 comme passerelle par défaut
    address 10.10.10.1/24

    # bridge-ports none = ce bridge n'est connecté à aucune carte réseau physique
    # C'est un réseau purement virtuel (interne à Proxmox)
    bridge-ports none

    # bridge-stp off = désactive le Spanning Tree Protocol
    # Pas nécessaire car il n'y a pas de boucle réseau possible
    bridge-stp off

    # bridge-fd 0 = forwarding delay à 0 seconde
    # Le bridge est opérationnel immédiatement au démarrage (pas d'attente)
    bridge-fd 0

    # ===== RÈGLE NAT (Network Address Translation) =====
    # C'est LA règle clé qui permet aux VMs d'accéder à Internet
    #
    # Comment ça marche :
    #   - Une VM (10.10.10.10) veut aller sur Internet (ex: apt update)
    #   - Le paquet arrive sur vmbr1 (gateway 10.10.10.1)
    #   - iptables REMPLACE l'IP source 10.10.10.10 par l'IP publique 51.158.200.50
    #   - Le paquet sort sur Internet via vmbr0
    #   - La réponse revient, iptables redirige vers la VM d'origine
    #
    # POSTROUTING = on modifie le paquet APRÈS le routage (juste avant qu'il sorte)
    # -s 10.10.10.0/24 = seulement les paquets venant du réseau privé
    # -o vmbr0 = seulement les paquets qui sortent vers Internet (via vmbr0)
    # -j MASQUERADE = remplace l'IP source par celle de vmbr0 (IP publique)
    post-up   iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE

    # Nettoyage : supprime la règle NAT quand le bridge est arrêté
    post-down iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE
```

Ensuite, activez le forwarding IP et redémarrez le réseau :

```bash
# ===== ACTIVER LE FORWARDING IP =====
# Par défaut, Linux ne transfère PAS les paquets entre ses interfaces réseau.
# Il faut activer le "forwarding" pour que Proxmox fasse office de routeur
# entre vmbr1 (réseau privé) et vmbr0 (Internet).
#
# Sans ça, les paquets des VMs arrivent sur vmbr1 mais ne sont jamais
# transférés vers vmbr0 → les VMs n'ont pas Internet.

# Activation immédiate (effet temporaire, perdu au reboot)
echo 1 > /proc/sys/net/ipv4/ip_forward

# Activation permanente (persiste après un reboot)
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Recharger la configuration sysctl pour appliquer sans reboot
sysctl -p

# Redémarrer le réseau pour activer le bridge vmbr1
systemctl restart networking

# ===== VÉRIFICATION =====
# Vérifier que vmbr1 existe et a l'IP 10.10.10.1
ip addr show vmbr1

# Vérifier que le forwarding est actif (doit afficher "1")
cat /proc/sys/net/ipv4/ip_forward

# Vérifier que la règle NAT est en place
iptables -t nat -L POSTROUTING -v
```

#### Résumé du flux réseau

```
VM (10.10.10.10) veut faire "apt update" :

1. VM envoie le paquet → destination: archive.ubuntu.com
   source: 10.10.10.10 (IP privée)

2. Le paquet arrive sur vmbr1 (gateway 10.10.10.1)

3. Le forwarding IP transfère le paquet de vmbr1 → vmbr0

4. La règle NAT MASQUERADE remplace :
   source: 10.10.10.10 → source: 51.158.200.50 (IP publique)

5. Le paquet sort sur Internet

6. La réponse revient à 51.158.200.50

7. iptables se souvient et redirige vers 10.10.10.10

8. La VM reçoit la réponse ✅
```

### Configuration de l'accès SSH (sur votre machine locale)

```bash
# 1. Générer une clé SSH si ce n'est pas fait
ssh-keygen -t ed25519 -f ~/.ssh/proxmox_key

# 2. Afficher votre clé publique
cat ~/.ssh/proxmox_key.pub

# 3. Sur la console Web Proxmox (https://51.158.200.50:8006 → Shell),
#    collez ces commandes pour autoriser votre clé :
mkdir -p /root/.ssh
chmod 700 /root/.ssh
# ⚠️ Remplacez la clé ci-dessous par VOTRE propre clé publique (résultat de cat ~/.ssh/proxmox_key.pub)
echo "VOTRE_CLE_PUBLIQUE_ICI" >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# 4. Testez la connexion depuis votre machine locale
ssh -i ~/.ssh/proxmox_key root@IP_PROXMOX
```

> **⚠️ IMPORTANT** : Si vos VMs utilisent le bridge `vmbr0` directement avec des IPs publiques ou un DHCP, adaptez `network_bridge` dans `terraform.tfvars` et la gateway en conséquence. Le NAT n'est nécessaire que si vous utilisez un sous-réseau privé.

---

## 🚀 Guide de Déploiement Manuel (étape par étape)

### ÉTAPE 1 : Configuration des variables

```bash
cd infrastructure/terraform/

# Éditez terraform.tfvars avec vos valeurs réelles
# IMPORTANT : Remplacez les valeurs suivantes :
#
#   - proxmox_node : le hostname de votre serveur Proxmox
#     → Pour le trouver, connectez-vous en SSH au serveur et tapez : hostname
#     → Ou dans l'interface Web Proxmox (https://IP:8006), panneau gauche sous "Datacenter"
#     → Par défaut c'est "pve", mais ça peut varier (ex: "sd-178488")
#
#   - ssh_public_key : votre clé SSH PUBLIQUE (PAS la clé privée !)
#     → Pour la récupérer : cat ~/.ssh/proxmox_key.pub
#     → C'est une SEULE ligne qui commence par "ssh-ed25519 AAAA..." ou "ssh-rsa AAAA..."
#     → ⚠️ Ne mettez JAMAIS la clé privée (celle sans .pub) ici
#
#   - storage_pool : le nom du pool de stockage Proxmox pour les disques des VMs
#     → Pour le trouver, sur le serveur Proxmox tapez : pvesm status
#     → Repérez le stockage de type zfspool, lvmthin ou lvm (ex: "vmdata", "local-lvm")
#
#   - proxmox_password : le mot de passe de connexion à l'API Proxmox
#
#   - domain : votre nom de domaine réel (ex: "onlineboutique.ip-ddns.com")
#
#   - acme_email : votre email pour les certificats Let's Encrypt
#
#   - network_bridge : le bridge réseau Proxmox (par défaut "vmbr0", ou "vmbr1" si réseau privé)
#
#   - Les IPs (master_ip, worker_ips, gateway_ip) : adaptez si votre réseau est différent
```

### ÉTAPE 2 : Provisioning de l'infrastructure (Terraform)

```bash
cd infrastructure/terraform/

# Initialisation de Terraform (télécharge le provider Proxmox)
terraform init

# Prévisualisation des changements (dry-run)
# Cela affiche les 3 VMs qui vont être créées sans les créer réellement
terraform plan -var-file=terraform.tfvars

# Application des changements (crée les VMs)
# Terraform va :
#   1. Cloner le template cloud-init 3 fois
#   2. Configurer les IPs via cloud-init
#   3. Configurer les clés SSH
#   4. Générer automatiquement l'inventaire Ansible
terraform apply -var-file=terraform.tfvars

# Vérification des outputs (affiche les IPs, noms, commandes SSH)
terraform output

# Afficher les commandes SSH pour se connecter aux VMs
terraform output ssh_commands
```

**Ce que fait Terraform ici :**
- Clone le template Ubuntu 22.04 cloud-init 3 fois (1 master + 2 workers)
- Attribue les IPs statiques du sous-réseau privé (10.10.10.10, .11, .12)
- Configure la gateway pour accéder à Internet via NAT
- Injecte la clé SSH publique pour l'accès sans mot de passe
- Génère automatiquement `../ansible/inventory/hosts.ini` et `../ansible/group_vars/all.yml`

#### Gestion du cycle de vie avec Terraform

Terraform gère entièrement le cycle de vie des VMs. **Ne supprimez JAMAIS les VMs
manuellement** sur Proxmox (via `qm destroy` ou l'interface web) — cela désynchronise
le state Terraform et crée des conflits.


### ÉTAPE 3 : Vérification de la connectivité SSH

Les VMs sont sur un **réseau privé** (10.10.10.0/24). Votre machine locale ne peut PAS
les atteindre directement. Il faut **rebondir** par le serveur Proxmox (jump host) :

```
Votre PC ──SSH──► Proxmox (51.158.200.50) ──SSH──► VM (10.10.10.x)
              IP publique                     réseau privé
```

L'option `-J` de SSH permet de faire ce rebond automatiquement :

```bash
# ⚠️ Connexion DIRECTE (ne marche PAS — réseau privé inaccessible) :
# ssh -i ~/.ssh/proxmox_key k8sadmin@10.10.10.10  ← TIMEOUT !

# ✅ Connexion via JUMP HOST (rebond par Proxmox) :
# -i ~/.ssh/proxmox_key = clé SSH pour les deux connexions (Proxmox + VM)
# -J root@51.158.200.50 = passer par Proxmox comme relais

# Master :
ssh -i ~/.ssh/proxmox_key -J root@51.158.200.50 k8sadmin@10.10.10.10

# Worker-1 :
ssh -i ~/.ssh/proxmox_key -J root@51.158.200.50 k8sadmin@10.10.10.11

# Worker-2 :
ssh -i ~/.ssh/proxmox_key -J root@51.158.200.50 k8sadmin@10.10.10.12

# Vérifiez que les VMs ont accès à Internet (via NAT)
ssh -i ~/.ssh/proxmox_key -J root@51.158.200.50 k8sadmin@10.10.10.10 "ping -c 3 8.8.8.8"
```

> **💡 Astuce** : Pour simplifier, ajoutez ceci dans `~/.ssh/config` sur votre machine locale :
> ```
> # Serveur Proxmox (jump host)
> Host proxmox
>     HostName 51.158.200.50
>     User root
>     IdentityFile ~/.ssh/proxmox_key
>
> # VMs Kubernetes (accès via Proxmox)
> Host k8s-master
>     HostName 10.10.10.10
>     User k8sadmin
>     IdentityFile ~/.ssh/proxmox_key
>     ProxyJump proxmox
>
> Host k8s-worker-*
>     User k8sadmin
>     IdentityFile ~/.ssh/proxmox_key
>     ProxyJump proxmox
>
> Host k8s-worker-1
>     HostName 10.10.10.11
>
> Host k8s-worker-2
>     HostName 10.10.10.12
> ```
> Après ça, il suffit de taper : `ssh k8s-master` ou `ssh k8s-worker-1`

### ÉTAPE 4 : Installation de Kubernetes (Ansible)

Les VMs sont sur un réseau privé → Ansible doit aussi passer par le **jump host Proxmox**.
Cette configuration est déjà intégrée dans l'inventaire généré par Terraform (`hosts.ini`)
grâce au paramètre `ProxyJump` dans `ansible_ssh_common_args`.

```bash
cd infrastructure/ansible/

# Vérification de l'inventaire (généré par Terraform)
# Vous devriez voir le ProxyJump dans [k8s_cluster:vars]
cat inventory/hosts.ini

# Test de connectivité Ansible (ping toutes les VMs via le jump host Proxmox)
# ⚠️ Pas besoin de --private-key ici : il est déjà dans l'inventaire
ansible all -i inventory/hosts.ini -m ping

# Si le test échoue, vérifiez :
#   1. Que les VMs sont bien démarrées : ssh sur Proxmox → qm list
#   2. Que cloud-init a configuré le réseau : ssh sur Proxmox → ping 10.10.10.10
#   3. Que votre clé SSH est bien copiée sur Proxmox (pour le jump host)

# Exécution du playbook complet
# Cela prend environ 15-20 minutes
ansible-playbook site.yml \
  -i inventory/hosts.ini \
  -v
```

**Ce que fait Ansible (dans l'ordre) :**

1. **Rôle `common`** (sur toutes les VMs) :
   - Met à jour le système (apt upgrade)
   - Installe les paquets prérequis (curl, gnupg, etc.)
   - Désactive le swap (obligatoire pour Kubernetes)
   - Configure les modules noyau (overlay, br_netfilter)
   - Configure sysctl (ip_forward, bridge-nf-call-iptables)
   - Met à jour /etc/hosts avec les IPs du cluster

2. **Rôle `kubernetes`** (sur toutes les VMs) :
   - Installe containerd comme runtime de conteneurs
   - Configure containerd pour utiliser systemd cgroup driver
   - Installe kubeadm, kubelet, kubectl (v1.29)
   - Verrouille les versions pour éviter les mises à jour accidentelles

3. **Rôle `master`** (sur le master uniquement) :
   - Initialise le cluster avec `kubeadm init`
   - Installe le réseau CNI Flannel (pod network)
   - Configure kubectl pour l'utilisateur
   - Génère le token de jonction pour les workers
   - Installe Helm 3
   - Sauvegarde le kubeconfig localement

4. **Rôle `worker`** (sur les workers) :
   - Récupère la commande de jonction depuis le master
   - Exécute `kubeadm join` pour rejoindre le cluster

5. **Rôle `k8s-components`** (sur le master) :
   - Installe les CRDs Gateway API
   - Installe Metrics Server (nécessaire pour HPA)
   - Installe **Traefik v3.2.1** via Helm (Ingress Controller + Gateway API)
   - Installe **Cert-Manager v1.16.2** via Helm
   - Crée les ClusterIssuers Let's Encrypt (production + staging)
   - Installe **ArgoCD v2.13.3** via Helm
   - Configure les HPAs (Horizontal Pod Autoscaler) pour l'autoscaling

### ÉTAPE 5 : Vérification du cluster Kubernetes

```bash
# Copier le kubeconfig localement
export KUBECONFIG=$(pwd)/../kubeconfig

# Vérifier les noeuds
kubectl get nodes -o wide
# Attendu: 3 noeuds en status "Ready" (1 master + 2 workers)

# Vérifier les composants système
kubectl get pods -n kube-system
kubectl get pods -n traefik
kubectl get pods -n cert-manager
kubectl get pods -n argocd

# Vérifier Traefik
kubectl get svc -n traefik

# Vérifier les ClusterIssuers
kubectl get clusterissuers

# Récupérer le mot de passe admin ArgoCD
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo  # nouvelle ligne
```

### ÉTAPE 6 : Configuration DNS

Avant de déployer l'application, configurez vos enregistrements DNS dans Cloud DNS :

```
api.VOTRE_DOMAIN       → IP publique du cluster (ou IP du load balancer Traefik)
dashboard.VOTRE_DOMAIN → IP publique du cluster
adminer.VOTRE_DOMAIN   → IP publique du cluster
argocd.VOTRE_DOMAIN    → IP publique du cluster
traefik.VOTRE_DOMAIN   → IP publique du cluster
```

> Si vous utilisez un sous-réseau privé avec NAT, vous devez configurer du port forwarding sur Proxmox pour exposer les ports 80 et 443 du NodePort Traefik.

### ÉTAPE 7 : Build des images Docker

```bash
# Retour à la racine du projet
cd ../../

# Build de l'image backend
docker build -t VOTRE_REGISTRY/fastapi-backend:latest ./backend

# Build de l'image frontend (avec l'URL de l'API)
docker build \
  --build-arg VITE_API_URL=https://api.VOTRE_DOMAIN \
  -t VOTRE_REGISTRY/fastapi-frontend:latest \
  ./frontend

# Push vers votre registry
docker push VOTRE_REGISTRY/fastapi-backend:latest
docker push VOTRE_REGISTRY/fastapi-frontend:latest
```

### ÉTAPE 8 : Déploiement de l'application via Helm

```bash
cd infrastructure/helm/fastapi-app/

# Mise à jour des dépendances Helm (PostgreSQL Bitnami)
helm dependency update

# Installation de l'application
helm upgrade --install fastapi-app . \
  --namespace fastapi-app \
  --create-namespace \
  -f values.yaml \
  -f values-production.yaml \
  --set global.domain="VOTRE_DOMAIN" \
  --set backend.image.repository="VOTRE_REGISTRY/fastapi-backend" \
  --set backend.image.tag="latest" \
  --set frontend.image.repository="VOTRE_REGISTRY/fastapi-frontend" \
  --set frontend.image.tag="latest" \
  --set backend.secrets.POSTGRES_PASSWORD="MOT_DE_PASSE_SECURE" \
  --set backend.secrets.SECRET_KEY="CLE_SECRETE_SECURE" \
  --set backend.secrets.FIRST_SUPERUSER="admin@votre-domain.com" \
  --set backend.secrets.FIRST_SUPERUSER_PASSWORD="MOT_DE_PASSE_ADMIN" \
  --set postgresql.auth.password="MOT_DE_PASSE_SECURE" \
  --set backend.env.FRONTEND_HOST="https://dashboard.VOTRE_DOMAIN" \
  --set backend.env.BACKEND_CORS_ORIGINS="https://dashboard.VOTRE_DOMAIN" \
  --set frontend.env.VITE_API_URL="https://api.VOTRE_DOMAIN" \
  --wait --timeout 600s

# Vérification
kubectl get all -n fastapi-app
kubectl get ingress -n fastapi-app
```

### ÉTAPE 9 : Configuration d'ArgoCD pour le GitOps

```bash
# Éditer infrastructure/argocd/application.yaml
# Remplacer VOTRE_ORG par votre organisation/utilisateur GitHub

# Appliquer les manifests ArgoCD
kubectl apply -f infrastructure/argocd/project.yaml
kubectl apply -f infrastructure/argocd/application.yaml

# Accéder à ArgoCD
# URL : https://argocd.VOTRE_DOMAIN
# User : admin
# Password : (récupéré à l'étape 5)
```

### ÉTAPE 10 : Vérification finale

```bash
# Tester les endpoints
curl -k https://api.VOTRE_DOMAIN/api/v1/utils/health-check/
curl -k https://dashboard.VOTRE_DOMAIN

# Vérifier les certificats TLS
echo | openssl s_client -connect api.VOTRE_DOMAIN:443 2>/dev/null | openssl x509 -noout -subject -issuer

# Vérifier le HPA
kubectl get hpa -n fastapi-app

# Vérifier ArgoCD
kubectl get applications -n argocd
```

---

## 🔄 Pipeline CI/CD (GitHub Actions)

Le pipeline `.github/workflows/ci-cd.yml` automatise tout le processus :

### Stages du pipeline

| Stage | Déclencheur | Actions |
|-------|-------------|---------|
| **infrastructure** | Manuel (`deploy_infra=true`) | Terraform init/plan/apply |
| **configure-k8s** | Après infrastructure | Ansible playbook complet |
| **build-test** | Push sur `main` | Lint + Tests + Coverage |
| **build-images** | Après build-test (sur `main`) | Build & Push Docker images |
| **deploy** | Après build-images (sur `main`) | Helm upgrade + ArgoCD sync |

### Secrets GitHub à configurer

| Secret | Description |
|--------|-------------|
| `PROXMOX_API_URL` | URL API Proxmox (ex: `https://51.158.200.50:8006/api2/json`) |
| `PROXMOX_USER` | Utilisateur Proxmox (ex: `root@pam`) |
| `PROXMOX_PASSWORD` | Mot de passe Proxmox |
| `SSH_PUBLIC_KEY` | Clé SSH publique pour les VMs |
| `SSH_PRIVATE_KEY` | Clé SSH privée pour Ansible |
| `DOCKER_USERNAME` | Utilisateur Docker Registry |
| `DOCKER_PASSWORD` | Mot de passe Docker Registry |
| `KUBECONFIG` | Kubeconfig encodé en base64 (fallback) |

### Variables GitHub à configurer

| Variable | Description | Exemple |
|----------|-------------|---------|
| `DOMAIN` | Nom de domaine | `myapp.example.com` |
| `ACME_EMAIL` | Email Let's Encrypt | `admin@example.com` |
| `DOCKER_REGISTRY` | URL du registry Docker | `ghcr.io/monorg` |
| `PROXMOX_NODE` | Nom du noeud Proxmox | `pve` |
| `VM_TEMPLATE` | Nom du template cloud-init | `ubuntu-2204-cloud` |
| `MASTER_IP` | IP du master | `10.10.10.10` |
| `WORKER_IP_1` | IP du worker 1 | `10.10.10.11` |
| `WORKER_IP_2` | IP du worker 2 | `10.10.10.12` |
| `GATEWAY_IP` | IP de la gateway | `10.10.10.1` |
| `STORAGE_POOL` | Pool de stockage (trouvez le vôtre avec `pvesm status` sur Proxmox) | `vmdata`, `local-lvm`, `local-zfs`... |
| `NETWORK_BRIDGE` | Bridge réseau | `vmbr0` |
| `VM_USER` | Utilisateur VM | `k8sadmin` |

---

## 🛠️ Commandes Utiles

### Terraform
```bash
terraform plan -var-file=terraform.tfvars    # Prévisualisation (dry-run, ne modifie rien)
terraform apply -var-file=terraform.tfvars   # Créer/Modifier les ressources
terraform destroy -var-file=terraform.tfvars # Supprimer TOUTES les ressources proprement
terraform state list                          # Liste des ressources dans le state
terraform refresh -var-file=terraform.tfvars # Resynchroniser le state avec Proxmox
terraform output                              # Afficher les outputs (IPs, commandes SSH)
terraform output ssh_commands                 # Afficher les commandes SSH uniquement
```

### Ansible
```bash
# La clé SSH et le ProxyJump sont déjà configurés dans l'inventaire hosts.ini
ansible-playbook site.yml -i inventory/hosts.ini --tags common      # Seul le rôle common
ansible-playbook site.yml -i inventory/hosts.ini --limit masters    # Seul le master
ansible all -i inventory/hosts.ini -m ping                          # Test de connectivité
ansible all -i inventory/hosts.ini -m shell -a "uptime"             # Commande sur toutes les VMs
```

### Kubernetes
```bash
kubectl get nodes -o wide                     # Noeuds du cluster
kubectl get all -n fastapi-app                # Toutes les ressources
kubectl logs -f deployment/fastapi-backend -n fastapi-app  # Logs backend
kubectl exec -it deployment/fastapi-backend -n fastapi-app -- bash  # Shell dans le backend
kubectl top nodes                             # Utilisation des ressources
kubectl top pods -n fastapi-app               # Utilisation par pod
```

### Helm
```bash
helm list -n fastapi-app                      # Charts installés
helm history fastapi-app -n fastapi-app       # Historique des releases
helm rollback fastapi-app 1 -n fastapi-app    # Rollback
helm uninstall fastapi-app -n fastapi-app     # Désinstallation
```

### ArgoCD
```bash
# Récupérer le mot de passe admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Installer le CLI ArgoCD
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# Login
argocd login argocd.VOTRE_DOMAIN --username admin --password <MOT_DE_PASSE>

# Sync manuel
argocd app sync fastapi-app

# Status
argocd app get fastapi-app
```

---

## ⚠️ Notes de Sécurité

1. **Ne committez JAMAIS** `terraform.tfvars` dans Git (contient des mots de passe)
2. **Changez tous les mots de passe** par défaut (`changethis`) avant le déploiement
3. **Désactivez Adminer** en production (`adminer.enabled: false` dans values-production.yaml)
4. **Utilisez des Sealed Secrets** ou **External Secrets** pour les secrets en production
5. **Le fichier `terraform.tfvars`** est dans le `.gitignore`

---

## 🔄 Tâches Réalisées

- [x] Analyse du code source de l'application FastAPI
- [x] Identification de l'architecture (Backend FastAPI + Frontend React + PostgreSQL + Traefik)
- [x] Création de la configuration Terraform (3 VMs Proxmox avec réseau privé)
- [x] Création du fichier `terraform.tfvars` avec les variables personnalisables
- [x] Création des rôles Ansible (common, kubernetes, master, worker, k8s-components)
- [x] Configuration de Traefik v3.2.1 avec Gateway API et Let's Encrypt
- [x] Configuration de Cert-Manager avec ClusterIssuers (prod + staging)
- [x] Configuration d'ArgoCD pour le déploiement GitOps
- [x] Création du Helm chart complet (Deployments, Services, Ingress, Secrets, HPA, Jobs)
- [x] Création des manifests ArgoCD (Application + Project)
- [x] Création du pipeline CI/CD GitHub Actions complet (5 stages)
- [x] Configuration du HPA pour l'autoscaling horizontal
- [x] Documentation complète (ce fichier)

---

## 👤 Rôle de l'Agent IA

Je suis un agent IA spécialisé en **DevOps**, déploiement automatisé cloud et on-premise. Mon rôle dans ce projet est de :

1. **Analyser** le code source de l'application FastAPI pour comprendre son architecture
2. **Concevoir** l'infrastructure complète (Terraform + Ansible + Kubernetes)
3. **Créer** tous les fichiers d'infrastructure-as-code
4. **Documenter** chaque étape pour permettre un déploiement manuel maîtrisé
5. **Automatiser** via un pipeline CI/CD complet

---

## 📞 Prochaines Étapes

1. **Préparer le template cloud-init** sur Proxmox (voir section Prérequis)
2. **Configurer le NAT** sur Proxmox pour le sous-réseau privé
3. **Générer une clé SSH** et mettre la clé publique dans `terraform.tfvars`
4. **Personnaliser `terraform.tfvars`** avec vos valeurs réelles
5. **Créer les enregistrements DNS** dans Cloud DNS
6. **Configurer le Docker Registry** (GitHub Container Registry, Docker Hub, etc.)
7. **Lancer le déploiement** (Terraform → Ansible → Helm)


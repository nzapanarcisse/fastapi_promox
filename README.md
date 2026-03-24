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

```bash
# Téléchargement de l'image cloud Ubuntu 22.04
cd /var/lib/vz/template/iso/
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Création de la VM template (ID 9000)
qm create 9000 --name ubuntu-2204-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import du disque
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Configuration du disque
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Configuration cloud-init
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0

# Installation de l'agent QEMU (important pour Terraform)
qm set 9000 --agent enabled=1

# Conversion en template
qm template 9000
```

### Configuration du NAT sur Proxmox (accès Internet pour le sous-réseau privé)

```bash
# Sur le serveur Proxmox, éditer /etc/network/interfaces
# Ajouter un bridge privé si nécessaire :

auto vmbr1
iface vmbr1 inet static
    address 10.10.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
    post-up   iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE
    post-down iptables -t nat -D POSTROUTING -s 10.10.10.0/24 -o vmbr0 -j MASQUERADE

# Activer le forwarding IP
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Redémarrer le réseau
systemctl restart networking
```

> **⚠️ IMPORTANT** : Si vos VMs utilisent le bridge `vmbr0` directement avec des IPs publiques ou un DHCP, adaptez `network_bridge` dans `terraform.tfvars` et la gateway en conséquence. Le NAT n'est nécessaire que si vous utilisez un sous-réseau privé.

---

## 🚀 Guide de Déploiement Manuel (étape par étape)

### ÉTAPE 1 : Configuration des variables

```bash
cd infrastructure/terraform/

# Éditez terraform.tfvars avec vos valeurs réelles
# IMPORTANT : Remplacez les valeurs suivantes :
#   - ssh_public_key : votre clé SSH publique (cat ~/.ssh/k8s_proxmox.pub)
#   - domain : votre nom de domaine réel
#   - acme_email : votre email pour Let's Encrypt
#   - Les IPs si votre réseau est différent
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

# Vérification des outputs
terraform output
```

**Ce que fait Terraform ici :**
- Clone le template Ubuntu 22.04 cloud-init 3 fois (1 master + 2 workers)
- Attribue les IPs statiques du sous-réseau privé (10.10.10.10, .11, .12)
- Configure la gateway pour accéder à Internet via NAT
- Injecte la clé SSH publique pour l'accès sans mot de passe
- Génère automatiquement `../ansible/inventory/hosts.ini` et `../ansible/group_vars/all.yml`

### ÉTAPE 3 : Vérification de la connectivité SSH

```bash
# Testez la connexion SSH à chaque VM
ssh -i ~/.ssh/k8s_proxmox k8sadmin@10.10.10.10  # master
ssh -i ~/.ssh/k8s_proxmox k8sadmin@10.10.10.11  # worker-1
ssh -i ~/.ssh/k8s_proxmox k8sadmin@10.10.10.12  # worker-2

# Vérifiez que les VMs ont accès à Internet
ssh -i ~/.ssh/k8s_proxmox k8sadmin@10.10.10.10 "ping -c 3 8.8.8.8"
```

### ÉTAPE 4 : Installation de Kubernetes (Ansible)

```bash
cd infrastructure/ansible/

# Vérification de l'inventaire (généré par Terraform)
cat inventory/hosts.ini

# Test de connectivité Ansible (ping toutes les VMs)
ansible all -i inventory/hosts.ini -m ping --private-key=~/.ssh/k8s_proxmox

# Exécution du playbook complet
# Cela prend environ 15-20 minutes
ansible-playbook site.yml \
  -i inventory/hosts.ini \
  --private-key=~/.ssh/k8s_proxmox \
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
| `STORAGE_POOL` | Pool de stockage | `local-lvm` |
| `NETWORK_BRIDGE` | Bridge réseau | `vmbr0` |
| `VM_USER` | Utilisateur VM | `k8sadmin` |

---

## 🛠️ Commandes Utiles

### Terraform
```bash
terraform plan -var-file=terraform.tfvars    # Prévisualisation
terraform apply -var-file=terraform.tfvars   # Application
terraform destroy -var-file=terraform.tfvars # Destruction
terraform state list                          # Liste des ressources
```

### Ansible
```bash
ansible-playbook site.yml -i inventory/hosts.ini --tags common      # Seul le rôle common
ansible-playbook site.yml -i inventory/hosts.ini --limit masters    # Seul le master
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


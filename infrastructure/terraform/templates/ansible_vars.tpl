---
# Variables Ansible générées automatiquement par Terraform
# Ne modifiez pas ce fichier manuellement

# ---- Kubernetes ----
k8s_master_ip: "${master_ip}"
k8s_worker_ips:
%{ for ip in worker_ips ~}
  - "${ip}"
%{ endfor ~}

k8s_version: "1.29"
k8s_pod_network_cidr: "10.244.0.0/16"
k8s_service_cidr: "10.96.0.0/12"

# ---- Domaine & TLS ----
domain: "${domain}"
acme_email: "${acme_email}"

# ---- Container Runtime ----
containerd_version: "1.7.*"

# ---- Traefik ----
traefik_version: "v3.2.1"
traefik_chart_version: "33.2.1"

# ---- Cert-Manager ----
cert_manager_version: "v1.16.2"

# ---- ArgoCD ----
argocd_version: "v2.13.3"
argocd_chart_version: "7.7.12"


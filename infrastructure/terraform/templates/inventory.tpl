[masters]
${master_ip} ansible_user=${ssh_user}

[workers]
%{ for ip in worker_ips ~}
${ip} ansible_user=${ssh_user}
%{ endfor ~}

[k8s_cluster:children]
masters
workers

[k8s_cluster:vars]
# Les VMs sont sur un réseau PRIVÉ (10.10.10.0/24) inaccessible depuis votre machine
# → Ansible doit passer par Proxmox (jump host) pour atteindre les VMs
# ProxyJump = rebondir via root@IP_PROXMOX avant d'atteindre la VM
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyJump=root@${proxmox_host}'
ansible_ssh_private_key_file=~/.ssh/proxmox_key
ansible_become=true


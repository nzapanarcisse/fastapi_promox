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
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_become=true


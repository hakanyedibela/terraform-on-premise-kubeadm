
output "control_plane_ip" {
  description = "IP address of the control plane node"
  value       = var.control_plane_host
}

output "worker_node_ips" {
  description = "IP addresses of worker nodes"
  value       = var.worker_nodes
}

output "kubeconfig_command" {
  description = "Command to copy kubeconfig from control plane"
  value       = "scp -i ${var.ssh_key_path} ${var.ssh_user}@${var.control_plane_host}:~/.kube/config ~/.kube/config"
}

output "cluster_status_command" {
  description = "Command to check cluster status"
  value       = "ssh -i ${var.ssh_key_path} ${var.ssh_user}@${var.control_plane_host} 'kubectl get nodes'"
}

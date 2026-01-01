
variable "control_plane_host" {
  description = "IP address or hostname of the control plane node"
  type        = string
}

variable "worker_nodes" {
  description = "List of IP addresses or hostnames for worker nodes"
  type        = list(string)
}

variable "ssh_user" {
  description = "SSH user for connecting to the servers"
  type        = string
  default     = "hkn"
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa_kubeadm"
}

variable "pod_network_cidr" {
  description = "CIDR for pod network (Calico default)"
  type        = string
  default     = "192.168.0.0/16"
}

variable "container_runtime" {
  description = "Container runtime to use (containerd or crio)"
  type        = string
  default     = "containerd"
}

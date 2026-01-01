
control_plane_host = "10.211.55.31"
worker_nodes = [
  "10.211.55.32",
  "10.211.55.33"
]

ssh_user     = "hkn"
ssh_key_path = "~/.ssh/id_rsa_kubeadm"

# Optional: Customize these if needed
pod_network_cidr = "192.168.0.0/16"

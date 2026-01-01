
terraform {
  required_version = ">= 1.0"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Create a temporary file with container runtime choice
resource "null_resource" "prepare_runtime_config" {
  provisioner "local-exec" {
    command = "echo '${var.container_runtime}' > /tmp/container.txt"
  }
}

# Install prerequisites and kubeadm tools on control plane
resource "null_resource" "setup_control_plane" {
  depends_on = [null_resource.prepare_runtime_config]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
    host        = var.control_plane_host
  }

  # Copy container runtime config
  provisioner "file" {
    source      = "/tmp/container.txt"
    destination = "/tmp/container.txt"
  }

  # Copy and execute configure-kubeadm.sh
  provisioner "file" {
    source      = "${path.module}/configure-kubeadm.sh"
    destination = "/tmp/configure-kubeadm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure-kubeadm.sh",
      "sudo /tmp/configure-kubeadm.sh"
    ]
  }

  # Copy and execute configure-kubeadm-tools.sh
  provisioner "file" {
    source      = "${path.module}/configure-kubeadm-tools.sh"
    destination = "/tmp/configure-kubeadm-tools.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure-kubeadm-tools.sh",
      "sudo /tmp/configure-kubeadm-tools.sh"
    ]
  }
}

# Initialize Kubernetes control plane
resource "null_resource" "init_control_plane" {
  depends_on = [null_resource.setup_control_plane]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
    host        = var.control_plane_host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm init --pod-network-cidr=${var.pod_network_cidr} --ignore-preflight-errors=NumCPU,Mem",
      "mkdir -p $HOME/.kube",
      "sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "echo 'Waiting for control plane to be ready...'",
      "sleep 30",
      "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml",
      "echo 'Waiting for Calico pods to start...'",
      "sleep 30",
      "kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n kube-system --timeout=300s || true",
      "kubectl wait --for=condition=ready pod -l k8s-app=calico-kube-controllers -n kube-system --timeout=300s || true",
      "echo 'Network plugin installation complete'"
    ]
  }

  # Extract join command
  provisioner "local-exec" {
    command = <<-EOT
      ssh -i ${var.ssh_key_path} -o StrictHostKeyChecking=no ${var.ssh_user}@${var.control_plane_host} \
        "sudo kubeadm token create --print-join-command" > ${path.module}/join-command.sh
    EOT
  }
}

# Install prerequisites and kubeadm tools on worker nodes
resource "null_resource" "setup_worker_nodes" {
  depends_on = [null_resource.prepare_runtime_config]
  count      = length(var.worker_nodes)

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
    host        = var.worker_nodes[count.index]
  }

  # Copy container runtime config
  provisioner "file" {
    source      = "/tmp/container.txt"
    destination = "/tmp/container.txt"
  }

  # Copy and execute configure-kubeadm.sh
  provisioner "file" {
    source      = "${path.module}/configure-kubeadm.sh"
    destination = "/tmp/configure-kubeadm.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure-kubeadm.sh",
      "sudo /tmp/configure-kubeadm.sh"
    ]
  }

  # Copy and execute configure-kubeadm-tools.sh
  provisioner "file" {
    source      = "${path.module}/configure-kubeadm-tools.sh"
    destination = "/tmp/configure-kubeadm-tools.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/configure-kubeadm-tools.sh",
      "sudo /tmp/configure-kubeadm-tools.sh"
    ]
  }
}

# Join worker nodes to the cluster
resource "null_resource" "join_worker_nodes" {
  depends_on = [
    null_resource.init_control_plane,
    null_resource.setup_worker_nodes
  ]
  count = length(var.worker_nodes)

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
    host        = var.worker_nodes[count.index]
  }

  provisioner "file" {
    source      = "${path.module}/join-command.sh"
    destination = "/tmp/join-command.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/join-command.sh",
      "sudo bash /tmp/join-command.sh",
      "echo 'Worker node joined successfully. Waiting for node to be ready...'",
      "sleep 20"
    ]
  }
}

# Verify cluster status
resource "null_resource" "verify_cluster" {
  depends_on = [null_resource.join_worker_nodes]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.ssh_key_path)
    host        = var.control_plane_host
  }

  provisioner "remote-exec" {
    inline = [
      "echo '=== Cluster Status ==='",
      "kubectl get nodes -o wide",
      "echo ''",
      "echo '=== Calico Pods Status ==='",
      "kubectl get pods -n kube-system -l k8s-app=calico-node -o wide",
      "echo ''",
      "echo '=== All System Pods ==='",
      "kubectl get pods -n kube-system",
      "echo ''",
      "echo 'Waiting for all nodes to be Ready...'",
      "kubectl wait --for=condition=ready nodes --all --timeout=300s || echo 'Some nodes may still be initializing'",
      "echo ''",
      "echo '=== Final Cluster Status ==='",
      "kubectl get nodes"
    ]
  }
}

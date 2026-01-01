
#!/bin/bash

CONTROL_PLANE="10.211.55.31"
WORKER_NODES=("10.211.55.32" "10.211.55.33")
SSH_USER="hkn"
SSH_KEY="~/.ssh/id_rsa_kubeadm"

echo "=== Kubernetes Cluster Cleanup ==="
echo ""

# Reset worker nodes first
echo "1. Resetting worker nodes..."
for NODE in "${WORKER_NODES[@]}"; do
    echo "   Resetting $NODE..."
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'sudo kubeadm reset -f'
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'sudo rm -rf /etc/cni/net.d'
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'sudo rm -rf $HOME/.kube'
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X'
    echo "   ✓ $NODE reset complete"
done

echo ""
echo "2. Resetting control plane..."
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'sudo kubeadm reset -f'
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'sudo rm -rf /etc/cni/net.d'
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'sudo rm -rf $HOME/.kube'
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X'
echo "   ✓ Control plane reset complete"

echo ""
echo "3. Restarting containerd on all nodes..."
for NODE in "${WORKER_NODES[@]}" "$CONTROL_PLANE"; do
    echo "   Restarting containerd on $NODE..."
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'sudo systemctl restart containerd'
done

echo ""
echo "=== Cleanup Complete ==="
echo "The cluster has been completely reset."
echo "You can now run 'terraform apply' to recreate it."

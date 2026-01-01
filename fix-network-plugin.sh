
#!/bin/bash

CONTROL_PLANE="10.211.55.31"
SSH_USER="hkn"
SSH_KEY="~/.ssh/id_rsa_kubeadm"

echo "=== Fixing Network Plugin Issues ==="
echo ""

echo "1. Reapplying Calico manifest..."
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml'

echo ""
echo "2. Waiting for Calico pods to restart..."
sleep 30

echo ""
echo "3. Checking Calico pod status..."
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl get pods -n kube-system -l k8s-app=calico-node'

echo ""
echo "4. Restarting kubelet on all nodes..."
for NODE in "10.211.55.31" "10.211.55.32" "10.211.55.33"; do
    echo "   Restarting kubelet on $NODE..."
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'sudo systemctl restart kubelet'
done

echo ""
echo "5. Waiting for nodes to stabilize..."
sleep 30

echo ""
echo "6. Final cluster status:"
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl get nodes'
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl get pods -n kube-system'


#!/bin/bash

CONTROL_PLANE="10.211.55.31"
SSH_USER="hkn"
SSH_KEY="~/.ssh/id_rsa_kubeadm"

echo "=== Checking Kubernetes Cluster Status ==="
echo ""

echo "1. Checking Node Status:"
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl get nodes -o wide'

echo ""
echo "2. Checking Calico Pods:"
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl get pods -n kube-system -l k8s-app=calico-node -o wide'

echo ""
echo "3. Checking All System Pods:"
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl get pods -n kube-system'

echo ""
echo "4. Checking CNI Configuration on Worker Nodes:"
for NODE in "10.211.55.32" "10.211.55.33"; do
    echo "   Checking $NODE:"
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'ls -la /etc/cni/net.d/ 2>/dev/null || echo "CNI directory not found"'
    ssh -i $SSH_KEY ${SSH_USER}@${NODE} 'ls -la /opt/cni/bin/ 2>/dev/null || echo "CNI binaries not found"'
done

echo ""
echo "5. Checking Calico Node Logs (if pods exist):"
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl logs -n kube-system -l k8s-app=calico-node --tail=50 --prefix=true 2>/dev/null || echo "No Calico pods found or not ready yet"'

echo ""
echo "6. Describing Nodes for Issues:"
ssh -i $SSH_KEY ${SSH_USER}@${CONTROL_PLANE} 'kubectl describe nodes | grep -A 10 "Conditions:\|Taints:"'

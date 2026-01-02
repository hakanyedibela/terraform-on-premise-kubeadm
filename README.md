# terraform-on-premise-kubeadm

### Generate SSH Key

```SHELL
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_kubeadm -N ""
```

### Copy to the servers 
```SHELL
ssh-copy-id hkn@10.211.55.31
```

### Init, Plan and Apply
> terraform init

> terraform plan

> terraform apply -auto-approve

### Clean-Up Workflow

```SHELL
# Step 1: Clean up the actual Kubernetes cluster
./cleanup-cluster.sh

# Step 2: Remove Terraform state
terraform destroy -auto-approve

# Step 3: Remove local files
rm -f join-command.sh
rm -f /tmp/container.txt

# Step 4: Recreate everything
terraform apply -auto-approve
```

### Fix only Network issues

```SHELL
# Just run the fix script
./fix-network-plugin.sh
```

### Complete Reset/Clean

```SHELL
./cleanup-cluster.sh
terraform destroy -auto-approve
terraform apply -auto-approve
```

### Fetch the kubeconfig 
> scp -i ~/.ssh/id_rsa_kubeadm hkn@10.211.55.31:~/.kube/config ~/.kube/config

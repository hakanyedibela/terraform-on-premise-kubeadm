# terraform-on-premise-kubeadm

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
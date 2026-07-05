export TF_VAR_wazuh_manager_ip="100.87.168.87"


echo "=== Step 1/2: Packer build ==="
packer build ami_generator_packer.pkr.hcl

echo "=== Step 2/2: Terraform apply ==="
terraform apply -auto-approve
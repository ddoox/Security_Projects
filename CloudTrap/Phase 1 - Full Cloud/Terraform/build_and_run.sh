export TF_VAR_wazuh_manager_ip="10.0.1.10"
export TF_VAR_honeypot_ip="10.0.2.10"


echo "=== Step 1/2: Packer build ==="
packer build ami_generator_packer.pkr.hcl

echo "=== Step 2/2: Terraform apply ==="
terraform apply -auto-approve
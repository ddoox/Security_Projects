export TF_VAR_wazuh_manager_ip="10.0.1.10"
export TF_VAR_honeypot_ip="10.0.2.10"


echo "=== Step 1/1: Terraform destroy ==="

terraform destroy -auto-approve
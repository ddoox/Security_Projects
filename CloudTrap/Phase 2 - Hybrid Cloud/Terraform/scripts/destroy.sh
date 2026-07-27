#!/bin/bash
set -e

cd "$(dirname "$0")/.."

export TF_VAR_wazuh_manager_ip="100.73.81.69"

# Not used in destroy - placeholder to disable interactive prompt
export TF_VAR_tailscale_authkey="unused-for-destroy"



echo "=== Step 1/1: Terraform destroy ==="

terraform destroy -auto-approve

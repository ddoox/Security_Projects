#!/bin/bash
set -e

cd "$(dirname "$0")/.."

export TF_VAR_wazuh_manager_ip="100.73.81.69"




echo "=== Step 1/1: Terraform apply ==="
terraform apply -auto-approve

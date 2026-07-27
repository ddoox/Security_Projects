#!/bin/bash
set -e

cd "$(dirname "$0")/.."

export TF_VAR_wazuh_manager_ip="10.0.1.10"


echo "=== Step 1/1: Terraform apply ==="
terraform apply -auto-approve

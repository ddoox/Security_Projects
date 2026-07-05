#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Step 1/2: Terraform destroy ==="
terraform destroy -auto-approve

echo "=== Step 2/2: Destroy all Packer AMIs and Snapshots ==="

destroy_all_amis() {
    local pattern=$1
    echo "Searching for AMIs matching: $pattern"
    
    ALL_AMIS=$(aws ec2 describe-images --owners self --filters "Name=name,Values=$pattern" --query 'Images[*].ImageId' --output text)
    
    AMI_ARRAY=($ALL_AMIS)
    
    if [ ${#AMI_ARRAY[@]} -eq 0 ]; then
        echo "No AMIs found for pattern $pattern."
        return
    fi

    for ami_id in "${AMI_ARRAY[@]}"; do
        if [ "$ami_id" != "None" ]; then
            echo "Destroying AMI: $ami_id"
            SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids "$ami_id" --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)
            
            aws ec2 deregister-image --image-id "$ami_id"
            
            SNAP_ARRAY=($SNAPSHOT_IDS)
            for snapshot in "${SNAP_ARRAY[@]}"; do
                if [ "$snapshot" != "None" ]; then
                    echo "Deleting snapshot: $snapshot"
                    aws ec2 delete-snapshot --snapshot-id "$snapshot"
                fi
            done
        fi
    done
}

destroy_all_amis "wazuh-server-*"
destroy_all_amis "honeypot-*"
echo "=== Cleanup completed! ==="
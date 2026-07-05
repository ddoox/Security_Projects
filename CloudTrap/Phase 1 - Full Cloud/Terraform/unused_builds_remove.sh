#!/bin/bash
set -e

echo "=== Starting Daily Packer AMI Cleanup ==="
echo "Keeping only the single newest version of each image..."

clean_old_amis() {
    local pattern=$1
    local name=$2

    echo "----------------------------------------"
    echo "Processing: $name (Pattern: $pattern)"

    # Pobieranie posortowanej listy ID
    ALL_AMIS=$(aws ec2 describe-images --owners self --filters "Name=name,Values=$pattern" --query 'sort_by(Images, &CreationDate)[*].ImageId' --output text)

    # Poprawne konwertowanie wyjścia AWS CLI na tablicę
    AMI_ARRAY=($ALL_AMIS)

    # Sprawdzenie długości tablicy
    if [ ${#AMI_ARRAY[@]} -le 1 ]; then
        echo "Found ${#AMI_ARRAY[@]} AMI(s). Nothing to delete."
        return
    fi

    # Ucinamy ostatni element (najnowsze AMI), zostawiamy resztę do usunięcia
    AMIS_TO_DELETE=("${AMI_ARRAY[@]:0:${#AMI_ARRAY[@]}-1}")

    echo "Found ${#AMI_ARRAY[@]} AMIs total. Deleting the oldest ${#AMIS_TO_DELETE[@]}..."

    for ami_id in "${AMIS_TO_DELETE[@]}"; do
        if [ "$ami_id" != "None" ]; then
            echo "-> Targeting old AMI: $ami_id"
            SNAPSHOT_IDS=$(aws ec2 describe-images --image-ids "$ami_id" --query 'Images[0].BlockDeviceMappings[*].Ebs.SnapshotId' --output text)
            
            echo "   Deregistering $ami_id..."
            aws ec2 deregister-image --image-id "$ami_id"
            
            SNAP_ARRAY=($SNAPSHOT_IDS)
            for snapshot in "${SNAP_ARRAY[@]}"; do
                if [ "$snapshot" != "None" ]; then
                    echo "   Deleting snapshot $snapshot..."
                    aws ec2 delete-snapshot --snapshot-id "$snapshot"
                fi
            done
        fi
    done
    echo "Cleanup for $name completed."
}

clean_old_amis "wazuh-server-*" "Wazuh Server AMIs"
clean_old_amis "honeypot-*" "Honeypot AMIs"

echo "----------------------------------------"
echo "=== Daily Cleanup Completed Successfully! ==="
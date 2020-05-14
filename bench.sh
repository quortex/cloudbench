#!/bin/bash

CAMPAIGN=$1
SHORT_CAMPAIGN="${CAMPAIGN%.*}"

if ! [ -f $CAMPAIGN ]; then
    echo "Failed to find campaign file: $CAMPAIGN"
    exit
fi

mkdir -p results

GCP_E2_FAMILY="gcp:e2-highcpu-16"
GCP_N1_FAMILY="gcp:n1-highcpu-16"
GCP_N2_FAMILY="gcp:n2-highcpu-16"
GCP_N2D_FAMILY="gcp:n2d-highcpu-16"
GCP_C2_FAMILY="gcp:c2-standard-16"
GCP="$GCP_E2_FAMILY $GCP_N1_FAMILY $GCP_N2_FAMILY $GCP_C2_FAMILY $GCP_N2D_FAMILY"

AWS_M5_FAMILY="aws:m5.4xlarge aws:m5a.4xlarge aws:m5n.4xlarge"
AWS_M4_FAMILY="aws:m4.4xlarge"
AWS_C5_FAMILY="aws:c5.4xlarge aws:c5n.4xlarge"
AWS_C4_FAMILY="aws:c4.4xlarge"
AWS="$AWS_M5_FAMILY $AWS_M4_FAMILY $AWS_C5_FAMILY $AWS_C4_FAMILY"

#############################################################################################
for instance in $GCP $AWS; do 

    # Extract cloud provider and machine type
    cloud_provider=$(echo $instance | cut -d':' -f 1)
    machine=$(echo $instance | cut -d':' -f 2)

    # Copy the campaign file to the ansible folder
    cp $CAMPAIGN ansible/campaign.json

    # Go for creating the infra, ansible and destroying the infra
    pushd infra/${cloud_provider} && \
        export TF_VAR_machine_type=$machine && \
        export TF_VAR_instance_type=$machine && \
        terraform apply -auto-approve -var-file=${cloud_provider}.tfvars && \
        ip=$(terraform output -json | jq -r .cloudperf_external_ip.value) && \
    popd
    pushd ansible && \
        cat inventory.yaml | sed "s/__HOST__/$ip/g" > ansible_inventory.yaml && \
        ANSIBLE_HOST_KEY_CHECKING=False \
        ansible-playbook playbook.yaml -i ansible_inventory.yaml -u admin --extra-vars "campaign=$SHORT_CAMPAIGN machine=$machine cloud_provider=$cloud_provider" &&
    popd
    pushd infra/${cloud_provider} && \
        terraform destroy -auto-approve -var-file=${cloud_provider}.tfvars && \
    popd
    
    # Delete the generated campaign file
    rm ansible/campaign.json
done

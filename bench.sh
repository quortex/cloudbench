#!/bin/bash

CAMPAIGN=$1
MACHINES=$2
SHORT_CAMPAIGN="${CAMPAIGN%.*}"

if ! [ -f $CAMPAIGN ]; then
    echo "Failed to find campaign file: $CAMPAIGN"
    echo "Usage: bench.sh [CAMPAIGN] [MACHINES]"
    exit
fi

if ! [ -f $MACHINES ]; then
    echo "Failed to find machine file: $MACHINES"
    echo "Usage: bench.sh [CAMPAIGN] [MACHINES]"
    exit
fi

mkdir -p results
cp $CAMPAIGN ansible/campaign.json

#############################################################################################
for cloud_provider in $(cat $MACHINES | jq -r .[].cloud_provider); do
    cp_list=$(cat $MACHINES | jq -r ".[] | select (.cloud_provider == \"$cloud_provider\")")
    for arch in $(echo $cp_list | jq -r '.architectures[].type'); do
        arch_list=$(echo $cp_list | jq -r ".architectures[] | select (.type == \"$arch\")")
        for machine in $(echo $arch_list | jq -r .machines[]); do
            
            echo "Processing $cloud_provider, $arch, $machine ..."

            #Go for creating the infra, ansible and destroying the infra
            pushd infra/${cloud_provider} && \
                export TF_VAR_machine_type=$machine && \
                export TF_VAR_instance_type=$machine && \
                export TF_VAR_arch=$arch && \
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
        done
    done
done
rm ansible/campaign.json

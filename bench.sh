#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_DIR="$CUR_DIR/logs"
RESULT_DIR="$CUR_DIR/results"

function help {
    echo "usage: bench.sh -h -c [CAMPAIGN_FILE] -m [MACHINE_FILE] -r [RESULT_DIR] -l [LOG_DIR]"
    echo "       [CAMPAIGN_FILE]: a json file describing the campaing to launch"
    echo "       [MACHINE_FILE]: a json file describing the machines to test on"
    echo "       [RESULT_DIR]: Optional, a directory where results will be stored, defaults to result/"
    echo "       [LOG_DIR]: Optional, a directory where logs will be stored, defaults to logs/"
    exit
}

while getopts “c:m:r:l:h” opt; do
  case $opt in
    h) help ;;
    c) CAMPAIGN=$OPTARG
       ;;
    m) MACHINES=$OPTARG
       ;;
    r)  RESULT_DIR=$OPTARG 
        if ! [[ "$RESULT_DIR" = /* ]]; then
            RESULT_DIR="$CUR_DIR/$RESULT_DIR"
        fi
       ;;
    l) LOG_DIR=$OPTARG 
        if ! [[ "$LOG_DIR" = /* ]]; then
            LOG_DIR="$CUR_DIR/$LOG_DIR"
        fi    
       ;;
  esac
done

if ! [ -f "$CAMPAIGN" ]; then
    echo "Failed to find campaign file: $CAMPAIGN"
    help
fi

if ! [ -f "$MACHINES" ]; then
    echo "Failed to find machine file: $MACHINES"
    help
fi

SHORT_CAMPAIGN="${CAMPAIGN%.*}"
mkdir -p $RESULT_DIR
mkdir -p $LOG_DIR
cp $CAMPAIGN $CUR_DIR/ansible/campaign.json

#############################################################################################
for cloud_provider in $(cat $MACHINES | jq -r .[].cloud_provider); do
    cp_list=$(cat $MACHINES | jq -r ".[] | select (.cloud_provider == \"$cloud_provider\")")
    for arch in $(echo $cp_list | jq -r '.architectures[].type'); do
        arch_list=$(echo $cp_list | jq -r ".architectures[] | select (.type == \"$arch\")")
        for machine in $(echo $arch_list | jq -r .machines[]); do
            
            #Go for creating the infra, ansible and destroying the infra
            echo "[$(date)] Creating infrastructure for $cloud_provider, $arch, $machine ..."
            pushd $CUR_DIR/infra/${cloud_provider} &> /dev/null && \
                export TF_VAR_machine_type=$machine && \
                export TF_VAR_instance_type=$machine && \
                export TF_VAR_arch=$arch && \
                terraform apply -auto-approve -var-file=${cloud_provider}.tfvars \
                &> "$LOG_DIR/${cloud_provider}-${arch}-${machine}.tfcreation" && \
                ip=$(terraform output -json | jq -r .cloudperf_external_ip.value) && \
            popd &> /dev/null && echo "[$(date)] Infrastructure created for $cloud_provider, $arch, $machine ..."

            echo "[$(date)] Launching ansible playbook for $cloud_provider, $arch, $machine ..."
            pushd $CUR_DIR/ansible &> /dev/null && \
                cat inventory.yaml | sed "s/__HOST__/$ip/g" > ansible_inventory.yaml && \
                ANSIBLE_HOST_KEY_CHECKING=False \
                ansible-playbook playbook.yaml -i ansible_inventory.yaml -u admin \
                                 --extra-vars "campaign=$SHORT_CAMPAIGN machine=$machine cloud_provider=$cloud_provider" \
                                 &> "$LOG_DIR/${cloud_provider}-${arch}-${machine}.ansible" && \
            popd &> /dev/null && echo "[$(date)] Ansible applied for $cloud_provider, $arch, $machine ..."

            echo "[$(date)] Destroying infrastructure for $cloud_provider, $arch, $machine ..."
            pushd $CUR_DIR/infra/${cloud_provider} &> /dev/null && \
                terraform destroy -auto-approve -var-file=${cloud_provider}.tfvars \
                &> "$LOG_DIR/${cloud_provider}-${arch}-${machine}.tfdestruction" && \
            popd &> /dev/null && echo "[$(date)] Infrastructure destroyed for $cloud_provider, $arch, $machine ..."
        done
    done
done
rm $CUR_DIR/ansible/campaign.json

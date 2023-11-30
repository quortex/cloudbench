#!/bin/bash

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
LOG_DIR="$CUR_DIR/logs"
RESULT_DIR="$CUR_DIR/results"
AWS_PROFILE=""
FFMPEG_VERSION=latest

function help {
    echo "usage: bench.sh -h -c [CAMPAIGN_FILE] -m [MACHINE_FILE] -r [RESULT_DIR] -l [LOG_DIR] -p [AWS_PROFILE]"
    echo "       [CAMPAIGN_FILE]: a json file describing the campaing to launch"
    echo "       [MACHINE_FILE]: a json file describing the machines to test on"
    echo "       [AWS_PROFILE]: The AWS Profile to use to authenticate/"
    echo "       [RESULT_DIR]: Optional, a directory where results will be stored, defaults to results/"
    echo "       [LOG_DIR]: Optional, a directory where logs will be stored, defaults to logs/"
    exit
}

while getopts “c:m:r:l:p:h” opt; do
  case $opt in
    h) help ;;
    c) CAMPAIGN=$OPTARG
       ;;
    p) AWS_PROFILE=$OPTARG
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

if [ "$AWS_PROFILE" == "" ]; then
    echo "An AWS Profile is required to authenticate"
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
        num_machines=$(echo $arch_list | jq '.machines | length')
        for idx in $(seq 0 $(($num_machines-1))); do
            machine=$(echo $arch_list | jq .machines[$idx])

            # Build a Terraform var file

            tfvar=$(mktemp)
            echo "arch = \"$arch\"" > $tfvar
            echo "usermail = \"$(git config user.email)\"" >> $tfvar
            echo "aws_profile = \"$AWS_PROFILE\"" > $tfvar
           
            if [ "$(echo $machine | jq -r type)" == "object" ]; then
                name=$(echo $machine | jq -r .name)

                num_pairs=$(echo $machine | jq '.vars | length')
                for j in $(seq 0 $(($num_pairs-1))); do
                    key=$(echo $machine | jq -r ".vars[$j].key")
                    value=$(echo $machine | jq ".vars[$j].value")
                    echo "$key = $value" >> $tfvar
                done
            else
                name=$(echo $machine | sed  's+\"++g')
                echo "instance_type = $machine" >> $tfvar
            fi

            # Create infra

            echo "[$(date)] Creating infrastructure for $cloud_provider, $arch, $name ..."
            pushd $CUR_DIR/infra/${cloud_provider} &> /dev/null
                ! [ -d .terraform ] && terraform init
                terraform apply -auto-approve -var-file=$tfvar -var-file=${cloud_provider}.tfvars &> "$LOG_DIR/${cloud_provider}-${arch}-${name}.tfcreation"
                ip=$(terraform output -json | jq -r .cloudperf_external_ip.value) 
                ssh_user=$(terraform output -json | jq -r .ssh_user.value)
            popd &> /dev/null && echo "[$(date)] Infrastructure created for $cloud_provider, $arch, $name ..."

            # Ansible
            echo "[$(date)] Launching ansible playbook for $cloud_provider, $arch, $name ..."
            pushd $CUR_DIR/ansible &> /dev/null
                cat inventory.yaml | sed "s/__HOST__/$ip/g" > ansible_inventory.yaml
                ANSIBLE_HOST_KEY_CHECKING=False \
                ansible-playbook playbook.yaml -i ansible_inventory.yaml -u $ssh_user \
                                 --extra-vars "campaign=$SHORT_CAMPAIGN machine=$name arch=$arch cloud_provider=$cloud_provider result_dir=$RESULT_DIR ff_ver=$FFMPEG_VERSION" \
                                 &> "$LOG_DIR/${cloud_provider}-${arch}-${name}.ansible"
            popd &> /dev/null && echo "[$(date)] Ansible applied for $cloud_provider, $arch, $name ..."

            # Destroy infra
            echo "[$(date)] Destroying infrastructure for $cloud_provider, $arch, $name ..."
            pushd $CUR_DIR/infra/${cloud_provider} &> /dev/null
            terraform destroy -auto-approve -var-file=$tfvar -var-file=${cloud_provider}.tfvars &> "$LOG_DIR/${cloud_provider}-${arch}-${name}.tfdestruction"
            popd &> /dev/null && echo "[$(date)] Infrastructure destroyed for $cloud_provider, $arch, $name ..."
        done
    done
done
rm $CUR_DIR/ansible/campaign.json

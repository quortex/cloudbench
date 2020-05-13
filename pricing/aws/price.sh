#!/bin/bash

machine=$1
model=$2
REGION=frankfurt
DATA="${REGION}.csv"

declare -A MODEL_POSITION=([machine]=1 [ondemand]=2 [preemptible]=3 [1yrcommit]=4 [3yrcommit]=5)

line=$(cat $DATA | grep "$machine;")
if [ "$line" == "" ]; then
    echo "Failed to find $machine in $DATA"
fi

position=${MODEL_POSITION[$model]}
echo "$machine"
total=$(echo $line | cut -d';' -f $position)
echo "Tot Price ($model, $ per hour): $(echo $total | sed "s/\./,/g")"

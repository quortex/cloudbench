#!/bin/bash

machine=$1
model=$2
REGION=ireland
DATA="${REGION}.csv"

declare -A MODEL_POSITION=([machine]=1 [ondemand]=2 [preemptible]=3 [1yrcommit]=4 [3yrcommit]=5)
declare -A SIZE_RATIO=([large]=1 [xlarge]=2 [2xlarge]=4 [4xlarge]=8 [8xlarge]=16)

type=$(echo $machine | cut -d'.' -f 1)
size=$(echo $machine | cut -d'.' -f 2)

line=$(cat $DATA | grep "$type\;")
if [ "$line" == "" ]; then
    echo "Failed to find $type in $DATA"
    exit
fi

position=${MODEL_POSITION[$model]}
ratio=${SIZE_RATIO[$size]}

if [ "$ratio" == "" ]; then 
    echo "$size is not a valid size"
    exit
fi

if [ "$position" == "" ]; then 
    echo "$model is not a valid price model"
    exit
fi

echo "$machine"
unit=$(echo $line | cut -d';' -f $position)
total=$(echo "$unit * $ratio" | bc)
echo "Tot Price ($model, $ per hour): $(echo $total | sed "s/\./,/g")"

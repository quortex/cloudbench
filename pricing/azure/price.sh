#!/bin/bash

machine=$1
model=$2
REGION=northeurope
DATA="${REGION}.csv"

declare -A MODEL_POSITION=([machine]=1 [ondemand]=2 [preemptible]=3 [1yrcommit]=4 [3yrcommit]=5)
declare -A SIZE_RATIO=([2]=1 [4]=2 [8]=4 [16]=8 [32]=16)

if [[ $machine =~ Standard_(.)([0-9]+)(.*) ]]; then
    family_base=${BASH_REMATCH[1]}
    cores=${BASH_REMATCH[2]}
    family_extension=${BASH_REMATCH[3]}

    family="Standard_$family_base$family_extension"

    line=$(cat $DATA | grep "$family\;")
    if [ "$line" == "" ]; then
        echo "Failed to find $family in $DATA"
        exit
    fi

    position=${MODEL_POSITION[$model]}
    ratio=${SIZE_RATIO[$cores]}

    if [ "$ratio" == "" ]; then 
        echo "$cores is not a valid size"
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
else
    echo "Failed to match"
fi


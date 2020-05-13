#!/bin/bash

machine=$1
model=$2
REGION=netherlands
DATA="${REGION}.csv"

declare -A MODEL_POSITION=([machine]=1 [ondemand]=2 [preemptible]=3 [1yrcommit]=4 [3yrcommit]=5)
declare -A SIZE_TO_RAM=([highcpu]=0.9 [standard]=3.75 [highmem]=6.5)

if [[ $machine =~ (.*)-(.*)-(.*) ]]; then
  family=${BASH_REMATCH[1]}
  type=${BASH_REMATCH[2]}
  size=${BASH_REMATCH[3]}
else
  echo "Machine $machine could not be identified"
  exit
fi

if [ $(cat $DATA | grep $family | wc -l) -eq 0 ]; then
  echo "$family: unknown family"
  exit
fi

if [ "${SIZE_TO_RAM[$type]}" == "" ]; then
  echo "$type: unknown type"
  exit
fi

cpu=$size
mem=$(echo "$size * ${SIZE_TO_RAM[$type]}" | bc)
position=${MODEL_POSITION[$model]}
cpu_unit_price=$(cat $DATA | grep "$family-" | grep cpu | cut -d';' -f $position)
cpu_price=$(echo "$cpu * $cpu_unit_price" | bc)
mem_unit_price=$(cat $DATA | grep "$family-" | grep ram | cut -d';' -f $position)
mem_price=$(echo "$mem * $mem_unit_price" | bc)

total=$(echo "$cpu_price + $mem_price" | bc)

echo "$machine: $cpu vCPUs, $mem GB of RAM"
echo "CPU Price ($model, $ per hour): $cpu_price"
echo "RAM Price ($model, $ per hour): $mem_price"
echo "Tot Price ($model, $ per hour): $total"




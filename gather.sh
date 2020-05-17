#!/bin/bash

OUTPUT=$1.csv
SUMMARY=$1-summary.csv
rm -f $OUTPUT
rm -f $SUMMARY

echo ${PWD}

function make_price {

    local cloud=$1
    local machine=$2
    local model=$3
    local duration=$4

    pushd pricing/$cloud &> /dev/null && \
        item_price=$(./price.sh $machine $model  | grep "Tot Price" | cut -d":" -f 2 | sed "s/\,/\./g") && \
    popd &> /dev/null

    price=$(echo "scale=10;$item_price * $duration / (1000*3600)" | bc)
    echo $price
}

for file in $(ls $1*.csv); do
    machine=$(echo $file |cut -d'-' -f 3- | rev | cut -d'.' -f 2- | rev)
    cloud=$(echo $file |cut -d'-' -f 2)
    echo "Processing $file ..."
    total_duration=0
    for line in $(cat $file); do
        duration=$(echo $line | rev | cut -d';' -f 1 | rev)
        total_duration=$(($total_duration + $duration))

        ondemand_price=$(make_price $cloud $machine "ondemand" $duration)
        preemptible_price=$(make_price $cloud $machine "preemptible" $duration)
        oneyrcommit_price=$(make_price $cloud $machine "1yrcommit" $duration)
        threeyrcommit_price=$(make_price $cloud $machine "3yrcommit" $duration)
        echo "$machine;$line;$ondemand_price;$preemptible_price;$oneyrcommit_price;$threeyrcommit_price" >> $OUTPUT
    done 
    ondemand_price=$(make_price $cloud $machine "ondemand" $total_duration)
    preemptible_price=$(make_price $cloud $machine "preemptible" $total_duration)
    oneyrcommit_price=$(make_price $cloud $machine "1yrcommit" $total_duration)
    threeyrcommit_price=$(make_price $cloud $machine "3yrcommit" $total_duration)
    echo "$cloud;$machine;$total_duration;$ondemand_price;$preemptible_price;$oneyrcommit_price;$threeyrcommit_price" >> $SUMMARY
done

echo "Done writing $OUTPUT and $SUMMARY"
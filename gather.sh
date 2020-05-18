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

filelist=$(ls $1-*.csv)

echo "Cloud Provider;Machine Type;File;Video PID;Duration;On-Demand Pricing (qxo);Preemptible Pricing (qxp);1 Year Commit Price (qx1);(3 Years Commit Price (qx3)" > $OUTPUT
echo "Cloud Provider;Machine Type;Total Duration;On-Demand Pricing (qxo);Preemptible Pricing (qxp);1 Year Commit Price (qx1);(3 Years Commit Price (qx3)" > $SUMMARY
for file in $filelist; do
    full_machine=$(echo $file |cut -d'-' -f 3- | rev | cut -d'.' -f 2- | rev)
    machine=$(echo $full_machine | cut -d'#' -f 1)
    cloud=$(echo $file |cut -d'-' -f 2)
    echo "Processing $file ..."


    if [[ $full_machine =~ (.*)\>(.*) ]]; then
        machine="${BASH_REMATCH[1]}"
    else
        machine=$full_machine
    fi

    total_duration=0
    for line in $(cat $file); do
        duration=$(echo $line | rev | cut -d';' -f 1 | rev)
        total_duration=$(($total_duration + $duration))

        ondemand_price=$(make_price $cloud $machine "ondemand" $duration)
        preemptible_price=$(make_price $cloud $machine "preemptible" $duration)
        oneyrcommit_price=$(make_price $cloud $machine "1yrcommit" $duration)
        threeyrcommit_price=$(make_price $cloud $machine "3yrcommit" $duration)
        echo "$cloud;$full_machine;$line;$ondemand_price;$preemptible_price;$oneyrcommit_price;$threeyrcommit_price" >> $OUTPUT
    done 
    ondemand_price=$(make_price $cloud $machine "ondemand" $total_duration)
    preemptible_price=$(make_price $cloud $machine "preemptible" $total_duration)
    oneyrcommit_price=$(make_price $cloud $machine "1yrcommit" $total_duration)
    threeyrcommit_price=$(make_price $cloud $machine "3yrcommit" $total_duration)
    echo "$cloud;$full_machine;$total_duration;$ondemand_price;$preemptible_price;$oneyrcommit_price;$threeyrcommit_price" >> $SUMMARY
done

echo "Done writing $OUTPUT and $SUMMARY"
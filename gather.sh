#!/bin/bash

OUTPUT=$1-raw.csv
SUMMARY=$1-summary.csv
PRICE=$1-price.csv
PACKAGE=$1.xls
rm -f $OUTPUT
rm -f $SUMMARY
rm -f $PRICE

echo ${PWD}

function get_raw_price {
    local cloud=$1
    local machine=$2
    local model=$3

    pushd pricing/$cloud &> /dev/null && \
        item_price=$(./price.sh $machine $model  | grep "Tot Price" | cut -d":" -f 2 | sed "s/\,/\./g") && \
    popd &> /dev/null

    echo $item_price
}

function make_price {
    local cloud=$1
    local machine=$2
    local model=$3
    local duration=$4

    item_price=$(get_raw_price $cloud $machine $model)
    price=$(echo "scale=10;$item_price * $duration / (1000*3600)" | bc)
    echo $price
}

filelist=$(ls $1-*.csv)

echo "Cloud Provider;Machine Type;File;Video PID;Input Duration;Processing Duration;On-Demand Pricing (qxo);Preemptible Pricing (qxp);1 Year Commit Price (qx1);(3 Years Commit Price (qx3)" > $OUTPUT
echo "Cloud Provider;Machine Type;Total Duration;On-Demand Pricing (qxo);Preemptible Pricing (qxp);1 Year Commit Price (qx1);(3 Years Commit Price (qx3)" > $SUMMARY
echo "Cloud Provider;Machine Type;On-Demand Pricing / h;Preemptible Pricing / h;1 Year Commit Price / h;3 Years Commit Price / h" > $PRICE

for file in $filelist; do
    full_machine=$(echo $file |cut -d'-' -f 3- | rev | cut -d'.' -f 2- | rev)
    machine=$(echo $full_machine | cut -d'#' -f 1)
    cloud=$(echo $file |cut -d'-' -f 2)
    echo "Processing $file ..."

    ondemand_price=$(get_raw_price $cloud $machine "ondemand")
    preemptible_price=$(get_raw_price $cloud $machine "preemptible")
    oneyrcommit_price=$(get_raw_price $cloud $machine "1yrcommit")
    threeyrcommit_price=$(get_raw_price $cloud $machine "3yrcommit")    

    echo "$cloud;$full_machine;$ondemand_price;$preemptible_price;$oneyrcommit_price;$threeyrcommit_price" >> $PRICE

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

echo "Done writing $OUTPUT, $SUMMARY and $PRICE"

if [ $(which ssconvert | wc -l) -eq 1 ]; then
    summary_comma="$(mktemp -d)/summary.csv"
    cat $SUMMARY | sed 's/\,/\./g' | sed 's/\;/\,/g' > $summary_comma
    price_comma="$(mktemp -d)/price.csv"
    cat $PRICE | sed 's/\,/\./g' | sed 's/\;/\,/g' > $price_comma
    raw_comma="$(mktemp -d)/raw.csv"
    cat $OUTPUT | sed 's/\,/\./g' | sed 's/\;/\,/g' > $raw_comma

    ssconvert --merge-to=$PACKAGE $summary_comma $price_comma $raw_comma &> /dev/null && echo "Done Writing $PACKAGE"
else
    echo "ssconvert is not installed, $PACKAGE won't be generated"
fi
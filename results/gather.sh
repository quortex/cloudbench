#!/bin/bash

OUTPUT=$1.csv
rm -f $OUTPUT

for file in $(ls $1*.csv); do
    machine=$(echo $file |cut -d'-' -f 3- | rev | cut -d'.' -f 2- | rev)
    cloud=$(echo $file |cut -d'-' -f 2)
    echo "Processing $file ..."
    for line in $(cat $file); do
        pushd ../pricing/$cloud &> /dev/null && \
            ondemand=$(./price.sh $machine ondemand  | grep "Tot Price" | cut -d":" -f 2) && \
            preemptible=$(./price.sh $machine preemptible  | grep "Tot Price" | cut -d":" -f 2) && \
            oneyrcommit=$(./price.sh $machine 1yrcommit  | grep "Tot Price" | cut -d":" -f 2) && \
            threeyrcommit=$(./price.sh $machine 3yrcommit  | grep "Tot Price" | cut -d":" -f 2) && \
        popd &> /dev/null 
        echo "$machine;$ondemand;$preemptible;$oneyrcommit;$threeyrcommit;$line" >> $OUTPUT
    done 
done

echo "Done writing $OUTPUT!"
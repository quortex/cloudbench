#!/bin/bash

OUTPUT=$1.csv
rm -f $OUTPUT

for file in $(ls $1*.csv); do
    machine=$(echo $file | cut -d'-' -f 2- | cut -d'.' -f 1)
    echo "Processing $file ..."
    for line in $(cat $file); do
        echo "$machine;$line" >> $OUTPUT
    done 
done

echo "Done writing $OUTPUT!"
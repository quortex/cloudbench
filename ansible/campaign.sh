#!/bin/bash

FFMPEG=ffmpeg
campaign=$1

function time2milli() {
    local tin=$1
    seconds=$(echo $tin | cut -d' ' -f 2 | cut -d'm' -f 2 | cut -d'.' -f 1)
    milli=$(echo $tin | cut -d' ' -f 2 | cut -d'm' -f 2 | cut -d'.' -f 2 | cut -d's' -f 1 | awk '{printf "%d",$0}')
    
    t=$((1000*$seconds+$milli))
    echo $t
}

function length {
    count=$(cat $campaign | jq .$1 | jq length)
    echo $(($count-1))
}

function item {
    echo "$(cat $campaign | jq -r .$1[$2])"
}

function launch() {
    local in=$1
    local video_pid=$2
    local encoding=$3
    local profile=$4

    resolution=$(echo $profile | cut -d'@' -f 1)
    bitrate=$(echo $profile | cut -d'@' -f 2)
    maxrate=$bitrate
    minrate=$bitrate
    bufsize=$bitrate
    name=$(echo $encoding | jq -r .name)

    rc=$(echo $encoding | jq .rc)
    preset=$(echo $encoding | jq -r .quality)
    deinterlacer=$(echo $encoding | jq -r .deinterlacer)
    cmd_rc="-x264-params nal-hrd=cbr"

    if [ "$deinterlacer" != "none" ]; then
        cmd_deint="-vf $deinterlacer"    
    else
        cmd_deint=""
    fi

    local cmd_common="$FFMPEG -y -i $in -map i:$video_pid -an -c:v libx264 -preset $preset -s $resolution $cmd_rc -b:v $bitrate -bufsize $bufsize -maxrate $maxrate -minrate $minrate $cmd_deint -f mpegts"
    t1=$((time $cmd_common /dev/null) 2>&1 | grep real)
    total=$(time2milli "$t1")
    echo "$(basename $in);$video_pid;$profile;$name;$total"
   }

for file_idx in $(seq 0 $(length files)); do
    url=$(item files $file_idx)
    file=$(basename $url)
    curl $url -o $file && ffprobe -v quiet $file -show_programs -print_format json > $file.json
    for video_pid in $(cat $file.json | jq -r '.programs[].streams[] | select(.codec_type == "video") | .id'); do
        for encoding_idx in $(seq 0 $(length encodings)); do
            encoding=$(item encodings $encoding_idx)
            for profile_idx in $(seq 0 $(length profiles)); do
                profile=$(item profiles $profile_idx)
                launch $file $video_pid "$encoding" $profile
            done
            wait
        done
    done
done

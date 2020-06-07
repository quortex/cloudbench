#!/bin/bash

FFMPEG=ffmpeg
campaign=$1
output=$2

rm -f $output

function length {
    count=$(cat $campaign | jq .$1 | jq length)
    echo $(($count-1))
}

function item {
    echo "$(cat $campaign | jq -r .$1[$2])"
}

function resolution {

    local profile="$1"
    local idx=$2

    res=$(echo $profile | jq -r .ladder[$idx] | cut -d'@' -f 1)
    echo $res
}

function bitrate {

    local profile="$1"
    local idx=$2

    res=$(echo $profile | jq -r .ladder[$idx] | cut -d'@' -f 2)
    echo $res
}

function launch() {
    local in=$1
    local video_pid=$2
    local video_duration=$3
    local encoding=$4
    local profile="$5"

    local name=$(echo $profile | jq -r .name)
    ladder_len=$(echo $profile | jq '.ladder | length')

    rc=$(echo $encoding | jq .rc)
    encoding_name=$(echo $encoding | jq -r .name)
    preset=$(echo $encoding | jq -r .quality)
    gop=$(echo $encoding | jq -r .gopsize)
    deinterlacer=$(echo $encoding | jq -r .deinterlacer)
    cmd_rc="-x264-params nal-hrd=cbr"

    if [ "$deinterlacer" != "none" ]; then
        deint="yadif"    
    else
        deint=""
    fi

    local cmd_common="$FFMPEG -y -i $in -map i:$video_pid \
                      -filter_complex '[0:v]$deint,split=$ladder_len$(for i in $(seq 0 $(($ladder_len-1))); do echo -n [out$i]; done)' \
                      $(for i in $(seq 0 $(($ladder_len-1))); do resolution=$(resolution "$profile" $i) && bitrate=$(bitrate "$profile" $i) && \
                                                              echo -n "-map '[out$i]' -c:v libx264 -g $gop -preset $preset -an -s $resolution \
                                                             -x264-params nal-hrd=cbr -b:v $bitrate -bufsize $bitrate -maxrate $bitrate -minrate $bitrate \
                                                             -f mpegts /dev/null "; done)"

    st=$(date +%s%3N) && eval $cmd_common && en=$(date +%s%3N)
    total=$(($en-$st))
    echo "$(basename $in);$video_pid;$video_duration;$encoding_name;$name;$total" >> $output
}

for file_idx in $(seq 0 $(length files)); do
    url=$(item files $file_idx)
    file=$(basename $url)
    curl $url -o $file && ffprobe -v quiet $file -show_programs -print_format json > $file.json
    for video_pid in $(cat $file.json | jq -r '.programs[].streams[] | select(.codec_type == "video") | .id'); do
        video_duration=$(cat $file.json | jq -r ".programs[].streams[] | select(.codec_type == \"video\") | select(.id == \"$video_pid\")" | jq -r .duration)
        for encoding_idx in $(seq 0 $(length encodings)); do
            encoding=$(item encodings $encoding_idx)
            for profile_idx in $(seq 0 $(length profiles)); do
                profile=$(item profiles $profile_idx)
                launch $file $video_pid  $video_duration "$encoding" "$profile"
            done
            wait
        done
    done
done

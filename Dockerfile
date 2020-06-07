FROM debian:buster

RUN apt-get update
RUN apt-get -y install jq
RUN apt-get -y install ffmpeg
RUN apt-get -y install curl

COPY ansible/campaign.sh /root
COPY campaign.json /root

WORKDIR /root

ENTRYPOINT ["./campaign.sh", "campaign.json", "/workspace/result.json"]
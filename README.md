# cloudbench
A project to bench ffmpeg performances and price for the major cloud providers

## Concept
Comparing performance and price of cloud compute instances is a complex task, given the diversity of architectures offered by the cloud providers. This project will deploy machines (using [Terraform](https://www.terraform.io) and code (using [ansible](https://www.ansible.com)) to bench the machine and gather the results in a CSV File.

### Under the hoods
- A debian 10 image is used with the latest official ffmpeg (from the debian repos), as well as some sample streams from the French free to air Terrestrial service (HD): https://tsduck.io/streams/?name=france-dttv
- The compute pricing are difficult to fetch automatically, hence prices are locally stored as of now (see [pricing/aws/frankfurt.csv](pricing/aws/frankfurt.csv) and [pricing/gcp/netherlands.csv](pricing/gcp/netherlands.csv))

## Pre-requisites
- Terraform, Ansible and jq need to be installed
- You must have a valid account on GCP, AWS and Azure

## How to use
- *campaign* files are json files that can easily modified to make more/less ffmpeg computing (see [campaign.json](campaign.json))
- *machine* files are json files that describe the machines to be used for testing (see [machines.json](machines.json))
```console
foo@bar:~$ ./bench.sh campaign.json machines.json
foo@bar:~$ ./gather.sh results/campaign
```

## TODO
- Azure support
- Automatic price update (static for now)
- Launch tests in parallel
- Support multi profile

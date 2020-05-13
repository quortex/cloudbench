# cloudbench
A project to bench ffmpeg performances and price for the major cloud providers

## Concept
Comparing performance and price of cloud compute instances is a complex task, given the diversity of architectures offered by the cloud providers. This project will deploy machines (using [Terraform](https://www.terraform.io) and code (using [ansible](https://www.ansible.com)) to bench the machine and gather the results in a CSV File.

### Under the hoods
- A debian 10 image is used with the latest official ffmpeg (from the debian repos), as well as some sample streams from the French free to air Terrestrial service (HD): https://tsduck.io/streams/?name=france-dttv
- The compute pricing are difficult to fetch automatically, hence prices are locally stored as of now (see [pricing/aws/frankfurt.csv](pricing/aws/frankfurt.csv) and [pricing/aws/frankfurt.csv](pricing/gco/netherlands.csv))

## Pre-requisites
- Terraform, Ansible and jq need to be installed
- You must have a valid account on GCP, AWS and Azure

## How to use
- *campaign* files are json files that can easily modified to make more/less ffmpeg computing (see [here](script/full.json))
- The machines to test on can be edited in the "all.sh" script itself
```console
foo@bar:~$ ./all.sh
foo@bar:~$ cd results && ./gather full
```

## TODO
- Azure support
- Automatic price update (static for now)

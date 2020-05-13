# cloudbench
A project to bench ffmpeg performances and price for the major cloud providers

## Concept
Comparing performance and price of cloud compute instances is a complex task, given the diversity of architectures offered by the cloud providers. This project will deploy machines (using [Terraform](https://www.terraform.io) and code (using [ansible](https://www.ansible.com)) to bench the machine and gather the results in a CSV File.

A debian 10 image is used with the latest official ffmpeg (from the debian repos), as well as some sample streams from the french free to air Terrestrial service (HD): https://tsduck.io/streams/?name=france-dttv

## Pre-requisites
- Terraform and Ansible need to be installed
- You must have a valid account on GCP, AWS and Azure
- 
## How to use
- *campaign* files are json files that can easily modified to make more/less ffmpeg computing (see [here](campaign.json))
- The machines to test on can be edited in the "bench.sh" script itself
```console
foo@bar:~$ ./bench.sh campaign.json
foo@bar:~$ ./gather.sh results/full
```

## TODO
- Azure support
- Automatic price update (static for now)

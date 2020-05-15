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
foo@bar:~$ cat results/campaign.csv | head
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf25-506MHz-2019-01-22.ts;0x78;1920x1080@6000000;fast;35553
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf25-506MHz-2019-01-22.ts;0x140;1920x1080@6000000;fast;38428
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf25-506MHz-2019-01-22.ts;0x1a4;1920x1080@6000000;fast;36509
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf25-506MHz-2019-01-22.ts;0x208;1920x1080@6000000;fast;41406
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf25-506MHz-2019-01-22.ts;0x26c;1920x1080@6000000;fast;46119
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf30-546MHz-2019-01-22.ts;0x78;1920x1080@6000000;fast;41040
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf30-546MHz-2019-01-22.ts;0xdc;1920x1080@6000000;fast;45156
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf30-546MHz-2019-01-22.ts;0x140;1920x1080@6000000;fast;41275
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf30-546MHz-2019-01-22.ts;0x1a4;1920x1080@6000000;fast;37311
a1.4xlarge; ,4656; ,1375; ,2933; ,2011;tnt-uhf30-546MHz-2019-01-22.ts;0x208;1920x1080@6000000;fast;43401
```

## TODO
- Azure support
- Automatic price update (static for now)
- Launch tests in parallel

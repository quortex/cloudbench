# cloudbench
A project to bench ffmpeg performances and price for the major cloud providers

## Concept
Comparing performance and price of cloud compute instances is a complex task, given the diversity of architectures offered by the cloud providers. This project will deploy machines (using Terraform) and code (using ansible) to bench the machine and gather the results in a CSV File.

## Pre-requisites
- Terraform, Ansible and jq need to be installed
- You must have a valid account on GCP, AWS and Azure

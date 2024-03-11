# Example : Basic Cloud Slurm-GCP Cluster with Single Instance Monitor
This example will deploy a basic Slurm-GCP cluster with an additional VM for hosting the Slurm-GCP Monitoring (Grafana) dashboard.


<!-- mdformat-toc start --slug=github --no-anchors --maxlevel=6 --minlevel=1 -->

- [Basic Cloud Slurm-GCP Cluster with Single Instance Monitor](#example-basic-cloud-slurm-gcp-cluster-with-single-instance-monitor)
  - [Overview](#overview)
  - [Usage](#usage)
  - [Dependencies](#dependencies)
  - [Example API](#example-api)

<!-- mdformat-toc end -->

## Overview

This example creates a [slurm_cluster](../../../../../slurm_cluster/README.md)
in cloud mode. It highly configurable through tfvars.

All other components required to support the Slurm cluster are not created: VPC;
subnetwork; firewall rules; service accounts.

## Usage

Modify [example.tfvars](./example.tfvars) with required and desired values.

Then perform the following commands on this
[terraform project](../../../../../docs/glossary.md#terraform-project) root
directory:

- `terraform init` to get the plugins
- `terraform validate` to validate the configuration
- `terraform plan -var-file=example.tfvars` to see the infrastructure plan
- `terraform apply -var-file=example.tfvars` to apply the infrastructure build
- `terraform destroy -var-file=example.tfvars` to destroy the built
  infrastructure

## Dependencies

- [slurm_cluster module](../../../../README.md#dependencies)

## Example API

For the terraform example API reference, please see
[README_TF.md](./README_TF.md).

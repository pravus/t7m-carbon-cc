# Terraform carbon.cc

This project contains Terraform configuration files for building carbon.cc infrastructure.

# Staging environment

The `staging` sub-directory contains the Terraform configuration for building `stage.carbon.cc`.

## Components

* A FreeBSD droplet named `test-1` and corresponding DNS `A` record for `test-1.carbon.cc` pointing to the droplet's assigned IP address
* A Kubernetes cluster named `staging`
* A Kubernetes Secret referencing the Docker registry credentials for pulling container images
* The NGINX Kubernetes Ingress Controller installed via helm
* A Load Balancer mapping HTTP/HTTPS traffic to the Ingress Controller
* Kubernetes Services and Deployments for running application containers
* A Kubernetes Ingress configured to route traffic to applications
* A DNS `A` record for `stage.carbon.cc` pointing to the load balancer's external IP address

## Pre-requisites

### API Token

In order for Terraform to use the DigitalOcean API an access token must generated.  This value is referenced as the `do_token`
variable in the Terraform provider configuration.  It can either be passed on the command line using `-var do_token=$TOKEN`
or by creating a `.tfvars` file and using the `-var-file=$FILENAME.tfvars` option.  An example variables file:

```terraform
do_token = "$TOKEN"
```

Examples assume a variables file named `staging.tfvars`.

### Docker Registry

A DigitalOcean Docker registry must exist and contain the images referenced in the Kubernetes deployments.

## Build

If building from scratch you will first need to run the `init` sub-command:

```bash
terraform init
```

A preview of what will be built can be viewed using the `plan` sub-command:

```bash
terraform plan -var-file=staging.tfvars
```

When ready to build use the `apply` sub-command:

```bash
terraform apply -var-file=staging.tfvars
```

## Destroy

The entire staging environment can be destroyed with the following command:

```bash
terraform apply -destroy -var-file=staging.tfvars
```

You can then clean the local Terraform environment:

```bash
rm -f .terraform terraform.tfstate terraform.tfstate.backup
```

## Limitations

At this time the apply step must be run twice to populate the DNS record for `stage.carbon.cc` since it is not immediately
available after the NGINX ingress has allocated the load balancer.

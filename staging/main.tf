variable "do_token" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "terraform" {
  name = "terraform"
}

data "digitalocean_domain" "carbon-cc" {
  name = "carbon.cc"
}

variable "region" {
  type    = string
  default = "nyc3"
}

variable "k8s_host" {
  type    = string
  default = "stage"
}

variable "docker_registry" {
  type    = string
  default = "registry-carbon-cc"
}

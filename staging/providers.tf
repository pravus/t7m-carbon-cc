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

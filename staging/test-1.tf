resource "digitalocean_droplet" "test-1" {
  name     = "test-1"
  image    = "freebsd-12-x64-zfs"
  region   = var.region
  size     = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
}

resource "digitalocean_record" "test-1" {
  domain = data.digitalocean_domain.carbon-cc.name
  type   = "A"
  name   = digitalocean_droplet.test-1.name
  value  = digitalocean_droplet.test-1.ipv4_address
}

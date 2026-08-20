resource "hcloud_ssh_key" "gitops" {
  name       = "${var.server_name}-ssh"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "hcloud_firewall" "gitops" {
  name = "${var.server_name}-firewall"

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = [var.ssh_allowed_cidr]
    description = "SSH access"
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"

    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]

    description = "HTTP access"
  }
}

resource "hcloud_server" "gitops" {
  name        = var.server_name
  server_type = var.server_type
  image       = var.image
  location    = var.location

  ssh_keys = [
    hcloud_ssh_key.gitops.id
  ]

  firewall_ids = [
    hcloud_firewall.gitops.id
  ]

  labels = {
    managed_by = "terraform"
    project    = "gitops-iac"
  }
}

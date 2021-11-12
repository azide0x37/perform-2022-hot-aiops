## acebox requires public IP address
resource "google_compute_address" "acebox" {
  for_each = var.users

  name     = "${var.name_prefix}-${each.key}-ipv4-addr-${random_id.uuid.hex}"
}

## Setup firewall
resource "google_compute_firewall" "acebox_firewall" {
  name    = "${var.name_prefix}-allow-https-${random_id.uuid.hex}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["443", "80", "31090"]
  }

  target_tags = ["${var.name_prefix}-${random_id.uuid.hex}"]
  source_ranges = ["0.0.0.0/0"]
}

## Create key pair
resource "tls_private_key" "acebox_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "acebox_pem" { 
  filename = "${path.module}/key"
  content = tls_private_key.acebox_key.private_key_pem
  file_permission = 400
}

## Create acebox host
resource "google_compute_instance" "acebox" {
  for_each = var.users

  name         = "${var.name_prefix}-${each.key}-${random_id.uuid.hex}"
  machine_type = var.acebox_size
  zone         = var.gcloud_zone

  boot_disk {
    initialize_params {
      image = var.acebox_os
      size  = "40"
    }
  }

  network_interface {
    network = "default"

    access_config {
      nat_ip = "${google_compute_address.acebox[each.key].address}"
    }
  }

  metadata = {
    sshKeys = "${var.acebox_user}:${tls_private_key.acebox_key.public_key_openssh}"
  }

  tags = ["${var.name_prefix}-${random_id.uuid.hex}"]

  connection {
    host        = self.network_interface.0.access_config.0.nat_ip
    type        = "ssh"
    user        = var.acebox_user
    private_key = tls_private_key.acebox_key.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
      "sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config",
      "sudo service ssh restart",
      "sudo usermod -aG sudo ${var.acebox_user}",
      "echo '${var.acebox_user}:${var.acebox_user}' | sudo chpasswd"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../install/setup.sh"
    destination = "~/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
        "sudo chmod +x ~/setup.sh",
        "sudo DT_ENV_URL=${var.dt_cluster_url}/e/${dynatrace_environment.vhot_env[each.key].id} DT_CLUSTER_TOKEN=${dynatrace_environment.vhot_env[each.key].api_token} shell_user=${var.acebox_user} DT_CREATE_ENV_TOKENS=true ~/setup.sh"
      ]
  }

}
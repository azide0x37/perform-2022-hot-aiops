output "acebox_ip" {
  value = {
    for index, user in var.users:
    user.email => "ssh -i key ${var.acebox_user}@${google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip}"
  }
}

output "login_info" {
  value = "Users without key can login with username: ${var.acebox_user}, password: ${var.acebox_password}"
}
output "ssh_login" {
  value = {
    for index, user in var.users:
    user.email => "ssh -i key ${var.acebox_user}@${google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip}"
  }
}

output "dashboard" {
  value = {
    for index, user in var.users:
    user.email => "http://dashboard.${google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip}.nip.io user: admin, password: dynatrace"
  }
}

output "login_info" {
  value = "Users without ssh key access can login with username: ${var.acebox_user}, password: ${var.acebox_password}"
}
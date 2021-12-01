output "ssh_login" {
  value = {
    for index, user in var.users:
    user.email => "ssh -i key ${var.acebox_user}@${google_compute_instance.acebox[index].network_interface[0].access_config[0].nat_ip}"
  }
}

output "dt_env_url" {
  value = {
    for index, user in var.users:
    user.email => "Environment URL: ${var.dt_cluster_url}/e/${dynatrace_environment.vhot_env[0].id}"
  }
}

output "login_info" {
  value = "Users without ssh key access can login with username: ${var.acebox_user}, password: ${var.acebox_password}"
}


output "login_info" {
  value = "Users without ssh key access can login with username: ${var.acebox_user}, password: ${var.acebox_password}"
}
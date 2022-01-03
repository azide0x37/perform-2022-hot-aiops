resource "dynatrace_environment" "vhot_env" {
  name = "${var.name_prefix}-${random_id.uuid.hex}"
  state = var.environment_state
}
resource "dynatrace_cluster_user_group" "vhot_groups" {


	name = "ext-group-${var.name_prefix}-${random_id.uuid.hex}"
	access_rights = jsonencode(
		{
			VIEWER = [
			  "${dynatrace_environment.vhot_env.id}"
			]
			MANAGE_SETTINGS = [
			  "${dynatrace_environment.vhot_env.id}"
			]
      AGENT_INSTALL = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      LOG_VIEWER = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      VIEW_SENSITIVE_REQUEST_DATA = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      CONFIGURE_REQUEST_CAPTURE_DATA = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      REPLAY_SESSION_DATA = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      REPLAY_SESSION_DATA_WITHOUT_MASKING = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      MANAGE_SECURITY_PROBLEMS = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
      MANAGE_SUPPORT_TICKETS = [
			  "${dynatrace_environment.vhot_env.id}"
      ]
		}
	)
}

resource "dynatrace_cluster_user" "vhot_users" {
  for_each = var.user

	user_id = var.user["email"]
	email = var.user["email"]
	first_name = var.user["firstName"]
	last_name = var.user["lastName"]
	groups = ["${dynatrace_cluster_user_group.vhot_groups.id}"]

}
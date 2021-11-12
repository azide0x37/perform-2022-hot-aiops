resource "dynatrace_environment" "vhot_env" {
  for_each = var.users

  name = "${var.name_prefix}-${each.key}-${random_id.uuid.hex}"
  state = var.environment_state
}

resource "dynatrace_cluster_user_group" "vhot_groups" {
  for_each = var.users

	name = "ext-group-${var.name_prefix}-${each.key}-${random_id.uuid.hex}"
	access_rights = jsonencode(
		{
			VIEWER = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
			]
			MANAGE_SETTINGS = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
			]
      AGENT_INSTALL = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      LOG_VIEWER = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      VIEW_SENSITIVE_REQUEST_DATA = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      CONFIGURE_REQUEST_CAPTURE_DATA = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      REPLAY_SESSION_DATA = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      REPLAY_SESSION_DATA_WITHOUT_MASKING = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      MANAGE_SECURITY_PROBLEMS = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
      MANAGE_SUPPORT_TICKETS = [
			  "${dynatrace_environment.vhot_env[each.key].id}"
      ]
		}
	)
}

resource "dynatrace_cluster_user" "vhot_users" {
  for_each = var.users

	user_id = each.value["email"]
	email = each.value["email"]
	first_name = each.value["firstName"]
	last_name = each.value["lastName"]
	groups = ["${dynatrace_cluster_user_group.vhot_groups[each.key].id}"]
}
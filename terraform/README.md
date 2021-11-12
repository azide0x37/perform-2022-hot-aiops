# perform-2022-hot-auto-remediation

1. All resouces can be destroyed with this command:

    ```bash
    terraform apply -var="environment_state=DISABLED" -target=dynatrace_environment.vhot_env -auto-approve && terraform destroy -auto-approve
    ```

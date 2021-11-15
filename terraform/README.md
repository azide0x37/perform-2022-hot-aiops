# perform-2022-hot-auto-remediation

## Using Terraform to spin up the HOT environments

At the moment, only GCP is supported with a ready-made Terraform config.

### Requirements

Terraform needs to be locally installed.
A GCP account is needed.

### Instructions

1. Prepare Service Account and download JSON key credentials in GCP.

    ```bash
    https://cloud.google.com/iam/docs/creating-managing-service-accounts
    ```

1. Initialize terraform

    ```bash
    terraform init
    ```

1. Create a `terraform.tfvars` file inside the *terraform/gcloud* folder
   It needs to contain the following as a minimum:

    ```hcl
    name_prefix          = "example-vhot-monaco"
    dt_cluster_url       = "https://{id}.managed-sprint.dynalabs.io" 
    dt_cluster_api_token = "{your_cluser_api_token}"
    gcloud_project       = "myGCPProject" # GCP Project you want to use
    gcloud_zone          = "us-central1-a" # GCP zone name
    gcloud_cred_file     = "/location/to/sakey.json" # location of the Service Account JSON created earlier
    users = {
      0 = {
        email = "user1@example.com"
        firstName = "John"
        lastName = "Smith"
      }
      1 = {
        email = "user2@example.com"
        firstName = "James"
        lastName = "Miner"
      }
    }
    ```

    Check out `variables.tf` for a complete list of variables

1. Verify the configuration by running `terraform plan`

    ```bash
    terraform plan
    ```

1. Apply the configuration

    ```bash
    terraform apply
    ```

1. All resouces can be destroyed with this command:

    ```bash
    terraform apply -var="environment_state=DISABLED" -target=dynatrace_environment.vhot_env -auto-approve && terraform destroy -auto-approve
    ```

### Using the environment

After provisioning, terraform will give the output of all the public ip addresses per user.

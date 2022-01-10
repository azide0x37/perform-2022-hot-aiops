# Exercise 1 - Setup environment

## step 1 - Review current environment state

Review what has been configure in your environment.

Services already installed:

- ubuntu libraries including jq,git
- Docker service
- K3s as our kubernetes cluster
- One agent using the bash installation script 

1. Get into the development environment
using the web terminal or a ssh client log into your VM. (Check the provided credentials on the Dynatrace University).

2. Run ```kubectl get po --all-namespaces ``` to visualize all the default pods running in your environment. 

3. Get into your Dynatrace instance and verify that the one agent is connected
![deploy](./images/deploy-state.png)

## step 2 - Install the first services

2. From your console run ```/home/$shell_user/perform-2022-hot-aiops/install/setup-3.sh ```.
 This script will:
 - Download the Keptn CLI
 - 

[Next](./exercise-2.md)
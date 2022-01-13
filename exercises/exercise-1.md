# Exercise 1 - Review & Setup environment

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

1. From your console run ```sudo /home/$shell_user/perform-2022-hot-aiops/install/setup-3.sh```.
 This script will execute the following:
 - Download the Keptn CLI
 - Install keptn in the Kubernetes cluster using helm
 - Install the ingress-nginx for service connectivity
 - Install the dynatrace-service for keptn
 - Configure the default keptn project

[Next](./exercise-2.md)
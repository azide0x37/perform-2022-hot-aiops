# Setup the environment

We will install/configure the require application into our demo environment to simulate a production application running.

1. Get into the development environment
using the console or a ssh client log into your VM. (Check the provided credentials on the Dynatrace University).
2. Run the configuration script (setup-1.sh) located in the folder.
```(bash)
./install/setup/setup-1.sh
```
3. Wait for the install process to end. This will install:
- Required libraries for Ubuntu 
- Docker service
- K3s as our kubernetes cluster
- Dynatrace one agent 
- Keptn CLI and control plane on the kubernetes cluster
- Ingress Nginx to route the traffic in the kubernetes cluster
- Ingress Reverse proxy to router part of the traffic to the outside service and part to upstream kubernetes
- Configure Keptn - Install dynatrace-service for QG check, configures ingress and sets Dynatrace project
- Install gitea as our local git repo and adds the local code
- Install and configure ansible AWX
- Install easytravel Angular version
- Auto remediation lab setup
  - Create an easytravel repo in gitea
  - Configure an easytravel project in keptn
  - Configure sli/slo for easytravel project for remediation validation





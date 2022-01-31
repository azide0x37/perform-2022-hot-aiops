# Exercise 2 - Setup gitea, AWX and EasyTravel
1.  Precheck:
    Make sure you have the helm repos added to your environment. In order to do that run:
    `helm repo list` and you should get something similar to:
    ```
        NAME            URL                                       
        gitea-charts    https://dl.gitea.io/charts/               
        incubator       https://charts.helm.sh/incubator          
        stable          https://charts.helm.sh/stable
    ```
    If not, you can add the repositories for helm by running 
    ```(bash)
        sudo helm repo add stable https://charts.helm.sh/stable
        sudo helm repo add incubator https://charts.helm.sh/incubator
        sudo helm repo add gitea-charts https://dl.gitea.io/charts/
    ```
    From your console run
    ```(bash)
    sudo -E bash /home/$shell_user/perform-2022-hot-aiops/install/setup-4.sh 
    ```
    This script will execute the following:
    - Configure gitea as our git repository manager for the remediation project
    - Create a repository with a remediation playbook to use with Ansible AWX.

1.  IMPORTANT! Execute ```source ~/.bashrc``` to refresh your bash command    before executing the next command.
    From your console run 
    ```(bash)
    sudo -E bash /home/$shell_user/perform-2022-hot-aiops/install/setup-5.sh 
    ```
    This script will execute the following:
    - Configure AWX to have a interface to manage Ansible.
    - Run an Ansible playbook to configure Ansible itself and add a remediation and a trigger memory-leak playbook.

1.  Execute ```source ~/.bashrc``` to refresh your bash command before executing the next command.
    From your console run  
    ```(bash)
    sudo -E bash /home/$shell_user/perform-2022-hot-aiops/install/setup-6.sh 
    ```
    This script will execute the following:
    - Setup EasyTravel application. This will be running directly on the VM and already has some API endpoints that will trigger performance problems to simulate some scenarios.
    - Configure a Dashboard application that will centralize the links to access all the applications in this session.
---
[Next exercise](./exercise-3.md)
# Exercise 2 - Setup gitea, AWX and EasyTravel

1. From your console run ```sudo /home/$shell_user/perform-2022-hot-aiops/install/setup-4.sh ```.
 This script will execute the following:
 - Configure gitea as our git repository manager for the remediation project
 - Create a repository with a remediation playbook to use with Ansible AWX.


 1. From your console run ```sudo /home/$shell_user/perform-2022-hot-aiops/install/setup-5.sh ```.
 This script will execute the following:
 - Configure AWX to have a interface to manage Ansible.
 - Run an Ansible playbook to configure Ansible itself and add a remediation and a trigger memory-leak playbook.

  1. From your console run ```sudo /home/$shell_user/perform-2022-hot-aiops/install/setup-6.sh ```.
  This script will execute the following:
  - Setup EasyTravel application. This will be running directly on the VM and already has some API endpoints that will trigger performance problems to simulate some scenarios.
  - Configure a Dashboard application that will centralize the links to access all the applications in this session.



[Next](./exercise-3.md)
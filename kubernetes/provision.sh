#!/bin/bash

DEST_DIR="/tmp/setup"
BRANCH_NAME="main"
GIT_URL="https://github.com/AlchemiistCreative/k8s4vagrant.git"
HOSTNAME=$(hostname)

# Define host entries for the cluster
KUBEMASTER_IP="172.16.0.10"
KUBENODE1_IP="172.16.0.11"
KUBENODE2_IP="172.16.0.12"


log() {
    echo "$1"
}

install_requirements(){
    #sudo yum update -y
    sudo yum install -y git ansible python3 >> /dev/null
}

export ANSIBLE_HOST_KEY_CHECKING=False


clone_repo(){
    # Check if the destination directory exists and is not empty
    if [ -d "${DEST_DIR}" ]; then
        if [ "$(ls -A ${DEST_DIR})" ]; then
            log "Directory ${DEST_DIR} already exists and is not empty. Attempting to pull updates."
            cd "${DEST_DIR}" || exit
            git pull origin "${BRANCH_NAME}" || { log "ERROR: Pulling latest updates."; exit 1; }
        else
            log "Directory ${DEST_DIR} exists but is empty. Proceeding with clone."
            git clone -b "${BRANCH_NAME}" "${GIT_URL}" "${DEST_DIR}" || { log "ERROR: Cloning project repo."; exit 1; }
        fi
    else
        log "Cloning repository as ${DEST_DIR} does not exist."
        git clone -b "${BRANCH_NAME}" "${GIT_URL}" "${DEST_DIR}" || { log "ERROR: Cloning project repo."; exit 1; }
    fi
}


update_hosts_file() {
    # Define the IP addresses


    # Add entries for all nodes to /etc/hosts if they don't already exist
    if ! grep -q "${KUBEMASTER_IP} kubemaster" /etc/hosts; then
        echo "${KUBEMASTER_IP} kubemaster" | sudo tee -a /etc/hosts
    fi

    if ! grep -q "${KUBENODE1_IP} kubenode01" /etc/hosts; then
        echo "${KUBENODE1_IP} kubenode01" | sudo tee -a /etc/hosts
    fi

    if ! grep -q "${KUBENODE2_IP} kubenode02" /etc/hosts; then
        echo "${KUBENODE2_IP} kubenode02" | sudo tee -a /etc/hosts
    fi
}


run_ansible(){
    # If the hostname is 'kubemaster', run the Ansible playbook
    if [[ "${HOSTNAME}" == "kubemaster" ]]; then
        mkdir -p /root/.ssh
        mv /tmp/id_rsa /root/.ssh/id_rsa
        log "Running Ansible playbook on kubemaster..."
        cd "${DEST_DIR}" || exit
        ansible-playbook -i inventories/hosts.yml playbook.yml || { log "ERROR: Running Ansible playbook."; exit 1; }
    else
        log "This node is not the kubemaster. Skipping Ansible playbook."
    fi
}

setup(){
    # Create the project directory
    sudo mkdir -p "${DEST_DIR}" >> /dev/null || { log "ERROR: Creating project directory."; exit 1; }

    # Install required packages
    install_requirements

    # Clone the repository
    clone_repo

    # Update the /etc/hosts file
    update_hosts_file

    # Run the Ansible playbook if it's the master node
    run_ansible
}

setup

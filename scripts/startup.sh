#!/usr/bin/env bash

## executing again metadata startup script
# sudo google_metadata_script_runner startup

## review the result of the metadata startup script
# sudo journalctl -u google-startup-scripts.service

# add user to, now is not called because maybe not need it
create_user() {
  useradd -m -p "" -s /bin/bash ${user}
  mkdir -p /home/${user}/.ssh
  echo "${cert}" > /home/${user}/.ssh/authorized_keys
  chown -R ${user}:${user} /home/${user}/.ssh
  chmod 0600 /home/${user}/.ssh/authorized_keys
  usermod -aG adm ${user}
  echo "${user} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${user}
}

install_docker() {
  # Uninstall old versions
  sudo apt-get remove docker docker-engine containerd runc -y
  # Update the apt package index and install packages to allow apt to use a repository over HTTPS
  sudo apt-get update -y
  sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common python3-pip virtualenv python3-setuptools -y
  # Add Docker’s official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  # Setup the repository
  echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  # Update the apt package index
  sudo apt-get update -y
  # Install Docker Engine, containerd, and Docker Compose
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y
  sudo pip install docker
  sudo usermod -aG docker ${user}
}

### main ###

if [[ ! -f /etc/startup_was_launched ]]; then
  hostnamectl set-hostname $(hostname -s).${domain}
  install_docker
fi

if [[ -f /etc/startup_was_launched ]]; then exit 0; fi

touch /etc/startup_was_launched

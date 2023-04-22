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

### main ###

if [[ ! -f /etc/startup_was_launched ]]; then
  hostnamectl set-hostname $(hostname -s).${domain}
fi

if [[ -f /etc/startup_was_launched ]]; then exit 0; fi

touch /etc/startup_was_launched

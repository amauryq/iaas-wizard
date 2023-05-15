variable "service_name" {
  description = "The name of the service to be created. Match with the configuration name"
}

variable "owner_keypair_user" {
  description = "The name of the remote admin user to create"
  default     = "ansible"
}

variable "owner_keypair_private_key" {
  description = "Private key to use to connect via ssh to the instance when running Ansible playbooks in GCP"
}

variable "owner_keypair_public_key" {
  description = "An ssh public key that will be copied as authorized key for the new `OWNER_KEYPAIR_USER` user. By default, it copies the key from the current system user running Ansible."
}

variable "config" {
}

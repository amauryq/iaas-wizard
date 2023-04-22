locals {
  service_name = "linux"

  config = var.config

  prefix = local.config.hostname

  creds = {
    user : var.owner_keypair_user,
    private_key : base64decode(var.owner_keypair_private_key)
    public_key : base64decode(var.owner_keypair_public_key)
  }

  startup = templatefile("scripts/startup.sh", {
    user   = local.creds.user
    cert   = local.creds.public_key
    name   = local.config.name
    domain = local.config.dns_managed_zone
  })

  shutdown = templatefile("scripts/shutdown.sh", {
  })
}

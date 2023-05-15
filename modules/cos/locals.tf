locals {
  service_name = "cos"

  config = var.config

  prefix = local.config.hostname

  creds = {
    user : var.owner_keypair_user,
    private_key : base64decode(var.owner_keypair_private_key)
    public_key : base64decode(var.owner_keypair_public_key)
  }

  container = {
    url      = local.config.container.url
    registry = split("/", local.config.container.url)[0]
    name     = split(":", (split("/", local.config.container.url)[3]))[0]
  }

  cloud_init = templatefile("${path.module}/cloud-init.yml", {
    creds     = local.creds
    container = local.container
    # domain     = local.config.dns_managed_zone
  })
}

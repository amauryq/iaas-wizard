module "linux" {
  source = "./modules/linux"
  config = local.config[0]

  owner_keypair_user        = var.owner_keypair_user
  owner_keypair_private_key = var.owner_keypair_private_key
  owner_keypair_public_key  = var.owner_keypair_public_key
}

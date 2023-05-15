module "ar" {
    source = "./modules/ar"
    config = local.config[0]
}

module "linux" {
  source = "./modules/linux"
  config = local.config[1]

  owner_keypair_user        = var.owner_keypair_user
  owner_keypair_private_key = var.owner_keypair_private_key
  owner_keypair_public_key  = var.owner_keypair_public_key
}

module "cos" {
  source = "./modules/cos"
  config = local.config[2]

  owner_keypair_user        = var.owner_keypair_user
  owner_keypair_private_key = var.owner_keypair_private_key
  owner_keypair_public_key  = var.owner_keypair_public_key

  depends_on = [ module.ar ]
}

# module "cos7" {
#   service_name = "cos7"

#   source = "./modules/cos7"
#   config = local.config[2]

#   owner_keypair_user        = var.owner_keypair_user
#   owner_keypair_private_key = var.owner_keypair_private_key
#   owner_keypair_public_key  = var.owner_keypair_public_key
# }

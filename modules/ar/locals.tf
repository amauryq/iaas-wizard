locals {
  service_name = "ar"

  config = var.config

  registries = local.config.repos
}

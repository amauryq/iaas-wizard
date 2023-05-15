data "google_compute_zones" "available" {
  project = local.config.project_id
  region  = local.config.region
  status  = "UP"
}

resource "random_shuffle" "zone" {
  input        = data.google_compute_zones.available.names
  result_count = 1
}

data "google_compute_network" "shared_vpc" {
  name    = local.config.vpc_name
  project = local.config.subnetwork_project
}

data "google_compute_subnetwork" "shared_subnet" {
  name    = local.config.subnetwork
  project = local.config.subnetwork_project
  region  = local.config.region
}

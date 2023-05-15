data "google_compute_zones" "available" {
  project = local.config.project_id
  region  = local.config.region
  status  = "UP"
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

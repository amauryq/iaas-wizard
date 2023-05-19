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

resource "google_compute_firewall" "default" {
  name    = "${local.prefix}-firewall"
  project = local.config.project_id
  network = data.google_compute_network.shared_vpc.id

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["wireguard"]
}

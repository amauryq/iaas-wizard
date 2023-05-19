data "google_compute_image" "default" {
  # name    = local.config.source_image
  family  = local.config.source_image_family
  project = local.config.source_image_project
}

data "google_service_account" "default" {
  account_id = local.config.service_account.email
}

resource "random_string" "default" {
  length  = 4
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "google_compute_instance" "cos" {
  name         = "${local.prefix}-${local.config.project_id}-${random_string.default.result}"
  project      = local.config.project_id
  zone         = random_shuffle.zone.result[0]
  description  = "${local.service_name} instance for cos testing purpose"
  machine_type = local.config.machine_type
  labels       = merge({ os = "cos" }, local.config.labels)
  tags         = local.config.tags

  boot_disk {
    initialize_params {
      image = data.google_compute_image.default.id
    }
    auto_delete = true
  }

  network_interface {
    network    = data.google_compute_network.shared_vpc.id
    subnetwork = data.google_compute_subnetwork.shared_subnet.id

    dynamic "access_config" {
      for_each = local.config.allow_public_access ? [1] : []
      content {
        nat_ip       = google_compute_address.default[0].address
        network_tier = "PREMIUM"
      }
    }
  }

  metadata = merge(local.config.environment, {
    block-project-ssh-keys = "TRUE"
    enable-oslogin         = "FALSE"
    environment            = join(" ", [for k, v in local.config.environment : "${k}"])
    user-data              = local.cloud_init
  })

  service_account {
    email  = data.google_service_account.default.email
    scopes = local.config.service_account.scopes
  }
}

# resource "google_dns_record_set" "dns" {
#   name         = "${google_compute_instance.cos.name}.${local.config.dns_managed_zone}."
#   managed_zone = replace(local.config.dns_managed_zone, ".", "-")
#   type         = "A"
#   ttl          = 300
#   rrdatas = [
#     google_compute_instance.cos.network_interface[0].network_ip
#   ]
#   project = local.config.dns_host_project
# }

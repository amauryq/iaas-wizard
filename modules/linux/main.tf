data "google_compute_image" "default" {
  #  name    = local.config.source_image
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

resource "google_compute_instance" "linux" {
  name         = "${local.prefix}-${random_string.default.result}"
  project      = local.config.project_id
  zone         = data.google_compute_zones.available.names[0]
  description  = "${local.service_name} instance for testing purpose"
  machine_type = local.config.machine_type
  labels       = local.config.labels
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
        network_tier = "STANDARD"
      }
    }
  }

  metadata = merge(local.config.environment, {
    block-project-ssh-keys = "TRUE"
    enable-oslogin         = "FALSE"
    startup-script         = local.startup
    shutdown-script        = local.shutdown
    ## Not sure if it is needed
    ssh-keys    = "${local.creds.user}:${local.creds.public_key}"
    environment = join(" ", [for k, v in local.config.environment : "${k}"])
  })

  service_account {
    email  = data.google_service_account.default.email
    scopes = local.config.service_account.scopes
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = local.config.allow_public_access ? self.network_interface[0].access_config[0].nat_ip : self.network_interface[0].network_ip
      user        = local.creds.user
      private_key = local.creds.private_key
      # https://github.com/hashicorp/terraform/issues/3423      
      agent = false
    }

    inline = ["echo SSH connection is OK", ]
  }
}

# resource "google_dns_record_set" "dns" {
#   name         = "${google_compute_instance.linux.name}.${local.config.dns_managed_zone}."
#   managed_zone = replace(local.config.dns_managed_zone, ".", "-")
#   type         = "A"
#   ttl          = 300
#   rrdatas = [
#     local.config.allow_public_access ? google_compute_instance.linux.network_interface[0].access_config[0].nat_ip : google_compute_instance.linux.network_interface[0].network_ip
#   ]
#   project = local.config.dns_host_project
# }

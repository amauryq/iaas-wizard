data "google_compute_image" "default" {
  # name    = local.config.source_image
  family  = local.config.source_image_family
  project = local.config.source_image_project
}

data "google_service_account" "default" {
  account_id = local.config.service_account.email
}

resource "google_compute_instance_template" "primary" {
  name                 = "${local.prefix}-template-primary"
  project              = local.config.project_id
  region               = local.config.region
  description          = "This template is used to create ${local.service_name} instances"
  machine_type         = local.config.machine_type
  labels               = merge({ os = "cos-${data.google_compute_image.default.labels.build_number}" }, local.config.labels)
  tags                 = local.config.tags
  can_ip_forward       = false
  instance_description = "${local.service_name} instance"

  disk {
    source_image      = data.google_compute_image.default.id
    disk_type         = local.config.disk_type
    disk_size_gb      = local.config.disk_size_gb
    labels            = merge({ os = "cos-${data.google_compute_image.default.labels.build_number}" }, local.config.labels)
    boot              = true
    auto_delete       = true
    resource_policies = []
  }

  network_interface {
    network    = data.google_compute_network.shared_vpc.id
    subnetwork = data.google_compute_subnetwork.shared_subnet.id
  }

  metadata = merge(local.config.environment, {
    block-project-ssh-keys = true
    enable-oslogin         = "FALSE"
    environment            = join(" ", [for k, v in local.config.environment : "${k}"])
    user-data              = local.cloud_init
  })

  service_account {
    email  = data.google_service_account.default.email
    scopes = local.config.service_account.scopes
  }

  scheduling {
    preemptible         = local.config.preemptible
    automatic_restart   = local.config.preemptible ? false : true
    on_host_maintenance = local.config.preemptible ? "TERMINATE" : "MIGRATE"
  }
}

# https://cloud.google.com/vpc/docs/provisioning-shared-vpc#terraform
resource "google_compute_region_instance_group_manager" "mig" {
  name               = "${local.prefix}-mig"
  project            = local.config.project_id
  region             = local.config.region
  base_instance_name = local.prefix
  target_size        = local.config.max_replicas

  version {
    instance_template = google_compute_instance_template.primary.id
    name              = "primary"
  }

  named_port {
    name = "http"
    port = local.config.port
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.hc.id
    initial_delay_sec = 300
  }
}

# https://cloud.google.com/load-balancing/docs/internal/int-tcp-udp-lb-tf-module-examples
# https://github.com/terraform-google-modules/terraform-docs-samples/blob/main/internal_tcp_udp_lb_with_mig_backend/main.tf

# Health Check
resource "google_compute_region_health_check" "hc" {
  name                = "${local.prefix}-hc"
  project             = local.config.project_id
  region              = local.config.region
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    port         = local.config.port
    request_path = "/"
  }
}

# Backend Service
resource "google_compute_region_backend_service" "bknd" {
  name                  = "${local.prefix}-bknd"
  project               = local.config.project_id
  region                = local.config.region
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.hc.id]
  timeout_sec           = 10
  session_affinity      = "GENERATED_COOKIE"
  backend {
    group           = google_compute_region_instance_group_manager.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# URL map
resource "google_compute_region_url_map" "urlmap" {
  name            = "${local.prefix}-urlmap"
  project         = local.config.project_id
  region          = local.config.region
  default_service = google_compute_region_backend_service.bknd.id
}

# HTTP target proxy
# https://cloud.google.com/load-balancing/docs/proxy-only-subnets#gcloud
resource "google_compute_region_target_http_proxy" "targetproxy" {
  name    = "${local.prefix}-targetproxy"
  project = local.config.project_id
  region  = local.config.region
  url_map = google_compute_region_url_map.urlmap.id
}

# Forwarding Rule
resource "google_compute_forwarding_rule" "fwdr" {
  name                  = "${local.prefix}-fwdr"
  project               = local.config.project_id
  region                = local.config.region
  ip_protocol           = "TCP"
  port_range            = local.config.port
  load_balancing_scheme = "INTERNAL_MANAGED"
  target                = google_compute_region_target_http_proxy.targetproxy.id
  allow_global_access   = true
  network               = data.google_compute_network.shared_vpc.id
  subnetwork            = data.google_compute_subnetwork.shared_subnet.id
  network_tier          = "PREMIUM"
}

# DNS Record for ILB
# resource "google_dns_record_set" "dns" {
#   name         = "${local.config.hostname}.${local.config.dns_managed_zone}."
#   managed_zone = replace(local.config.dns_managed_zone, ".", "-")
#   type         = "A"
#   ttl          = 300
#   rrdatas      = [google_compute_forwarding_rule.fwdr.ip_address]
#   project      = local.config.dns_host_project
# }

output "config" {
  value = local.config
}

output "instance_dns" {
  value = {
    name        = "${google_compute_instance.cos.name}.${local.config.dns_managed_zone}"
    internal_ip = google_compute_instance.cos.network_interface[0].network_ip
    external_ip = local.config.allow_public_access ? google_compute_instance.cos.network_interface[0].access_config[0].nat_ip : "none"
  }
}
output "config" {
  value = local.config
}

output "lb_dns" {
  value = {
    name       = google_dns_record_set.dns.name
    ip_address = element(flatten(google_dns_record_set.dns.rrdatas), 0)
  }
}

output "mig" {
  value = google_compute_region_instance_group_manager.mig.self_link
}

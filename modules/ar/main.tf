resource "google_artifact_registry_repository" "ar" {
  for_each      = { for r in local.registries : r.repo_id => r }
  repository_id = each.value.repo_id
  format        = each.value.format
  project       = each.value.project_id
  location      = each.value.region
  description   = each.value.description
  labels        = each.value.labels
}

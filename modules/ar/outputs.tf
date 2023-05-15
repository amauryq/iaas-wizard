output "url" {
  value = [for k, v in google_artifact_registry_repository.ar : v][*].id
}

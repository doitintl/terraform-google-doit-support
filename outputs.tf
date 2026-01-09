output "project_id" {
  description = "The GCP project ID where access was granted"
  value       = var.project_id
}

output "group_id" {
  description = "The Google Group email address that was granted access"
  value       = local.group_id
}

output "iam_member_ids" {
  description = "Map of role names to their IAM member resource IDs for tracking the granted permissions"
  value       = { for role, resource in google_project_iam_member.gemini_roles : role => resource.id }
}

output "api_service_id" {
  description = "The ID of the enabled Gemini Cloud Assist API service resource"
  value       = google_project_service.gemini_cloud_assist_api.id
}

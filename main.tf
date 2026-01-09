locals {
  group_id = "ticket-${var.ticket_number}@cre.doit-intl.com"
  gemini_roles = {
    viewer             = "roles/viewer"
    user               = "roles/geminicloudassist.user"
    investigation_user = "roles/geminicloudassist.investigationUser"
  }
}

# API Service for Gemini Cloud Assist
resource "google_project_service" "gemini_cloud_assist_api" {
  project            = var.project_id
  service            = "geminicloudassist.googleapis.com"
  disable_on_destroy = var.disable_on_destroy
}

# IAM Members for Gemini Cloud Assist
resource "google_project_iam_member" "gemini_roles" {
  for_each = local.gemini_roles

  project = var.project_id
  role    = each.value
  member  = "group:${local.group_id}"

  depends_on = [
    google_project_service.gemini_cloud_assist_api
  ]
}

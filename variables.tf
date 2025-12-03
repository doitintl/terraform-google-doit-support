variable "project_id" {
  description = "The ID of the GCP project to grant access to"
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id must not be empty."
  }
}

variable "group_id" {
  description = "The email address of the Google Group to grant access to (e.g., team@example.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.group_id))
    error_message = "The group_id must be a valid email address."
  }
}

variable "disable_on_destroy" {
  description = "Whether to disable the Gemini Cloud Assist API when the resource is destroyed. Set to true to disable the API on destroy (recommended for temporary access), or false to keep the API enabled after resource destruction."
  type        = bool
  default     = true
}

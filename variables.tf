variable "project_id" {
  description = "The ID of the GCP project to grant access to"
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "The project_id must not be empty."
  }
}

variable "ticket_number" {
  description = "The number of your DoiT support ticket"
  type        = number

  validation {
    condition     = var.ticket_number > 0
    error_message = "The ticket_number must be a positive number."
  }
}

variable "disable_on_destroy" {
  description = "Whether to disable the Gemini Cloud Assist API when the resource is destroyed. Set to true to disable the API on destroy, or false to keep the API enabled after resource destruction."
  type        = bool
  default     = false
}

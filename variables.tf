

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default = "projecta-418002"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "google_credentials_file" {}
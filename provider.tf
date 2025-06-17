

variable "google_credentials" {
  type = string
}

provider "google" {
  credentials = var.google_credentials
  project     = "projecta-418002"
  region      = "us-central1"
}
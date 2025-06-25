

provider "google" {
 
  project     = "projecta-418002"
  region      = "us-central1"
  credentials = file(var.google_credentials_file)
}

terraform {
  backend "gcs" {
    bucket  = "sumitk-bucket"   # <-- replace with your bucket name
    prefix  = "opa/terraform.tfstate"      # folder path inside bucket
  }
}

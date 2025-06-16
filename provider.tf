provider "google" {
  project     = "projecta-418002"
  region      = "us-central1"
  credentials = file("key.json")

}
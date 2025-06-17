


# Random suffix for unique naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Storage bucket
resource "google_storage_bucket" "test_bucket" {
  name     = "terraform-test-bucket-${random_id.bucket_suffix.hex}"
  location = var.region

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

# Upload a test file to the bucket
resource "google_storage_bucket_object" "test_file" {
  name   = "test-file.txt"
  bucket = google_storage_bucket.test_bucket.name
  content = "Hello from Terraform on GCP!"
}

# Compute Engine instance
resource "google_compute_instance" "test_vm" {
  name         = "terraform-test-vm"
  machine_type = "e2-small"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    echo "Hello from Terraform VM!" > /tmp/terraform-test.txt
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF

  tags = ["terraform-test"]
}

# Firewall rule to allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "terraform-test-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["terraform-test"]
}



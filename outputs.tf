


# Outputs
output "bucket_name" {
  description = "Name of the created storage bucket"
  value       = google_storage_bucket.test_bucket.name
}

output "bucket_url" {
  description = "URL of the created storage bucket"
  value       = google_storage_bucket.test_bucket.url
}

output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = google_compute_instance.test_vm.network_interface[0].access_config[0].nat_ip
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = google_compute_instance.test_vm.network_interface[0].network_ip
}
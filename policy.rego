# Very Simple GCP Terraform Rego Policy (New OPA syntax)
package terraform.gcp

import rego.v1

# Deny if compute instances are not e2-micro
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_instance"
    resource.change.after.machine_type != "e2-micro"
    msg := "Only e2-micro instances allowed"
}

# Deny if storage buckets don't have versioning
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_storage_bucket"
    versioning := resource.change.after.versioning[_]
    versioning.enabled != true
    msg := "Storage buckets must have versioning enabled"
}

# Deny if firewall allows SSH (port 22) from internet
deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "google_compute_firewall"
    rule := resource.change.after
    "0.0.0.0/0" in rule.source_ranges
    port := rule.allow[_].ports[_]
    port == "22"
    msg := "Firewall rule cannot allow SSH (port 22) from internet (0.0.0.0/0)"
}
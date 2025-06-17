
# Rego Policy Explanation - Simple Notes

## What is this file?
This is a **Rego policy file** that acts like a security guard for your Terraform configurations. It checks your infrastructure code BEFORE you deploy it to catch problems early.

## File Structure Breakdown

### 1. Header Section

```rego
package terraform.gcp
import rego.v1
```

* **package**: Like a folder name - organizes your rules
* **import rego.v1**: Uses the latest Rego language features

### 2. The Rules (3 Security Checks)

#### Rule 1: Cost Control

```rego
deny contains msg if {
    resource.type == "google_compute_instance"
    resource.change.after.machine_type != "e2-micro"
    msg := "Only e2-micro instances allowed"
}
```

**What it does**: Only allows small, cheap VM instances  
**Why**: Prevents accidentally creating expensive servers

#### Rule 2: Data Protection

```rego
deny contains msg if {
    resource.type == "google_storage_bucket"
    versioning.enabled != true
    msg := "Storage buckets must have versioning enabled"
}
```

**What it does**: Forces backup/versioning on storage buckets  
**Why**: Protects against accidental data loss

#### Rule 3: Security Control

```rego
deny contains msg if {
    resource.type == "google_compute_firewall"
    "0.0.0.0/0" in rule.source_ranges
    port == "22"
    msg := "Cannot allow SSH from internet"
}
```

**What it does**: Blocks SSH access from the entire internet  
**Why**: Prevents hackers from accessing your servers

## How it Works (Simple Flow)

1. **Input**: Your Terraform plan (what you want to build)
2. **Process**: Rego checks each resource against the rules
3. **Output**:
   * `[]` = All good, deploy away! ✅
   * `["error message"]` = Stop! Fix the issues first ❌

## Key Concepts

| Term | Simple Explanation |
|------|-------------------|
| `deny` | Rules that BLOCK deployment |
| `contains msg if` | "If this condition is true, show this error message" |
| `resource_changes[_]` | "Check every resource in the plan" |
| `0.0.0.0/0` | "The entire internet" (security risk) |

## Benefits for Your Team

* **Catch mistakes early** - Before they cost money
* **Enforce standards** - Everyone follows the same rules
* **Improve security** - Automatic security checks
* **Save time** - No manual reviews needed

## Quick Command Reference

```bash
# Check if your plan passes the policy
opa eval -d policy.rego -i tfplan.json "data.terraform.gcp.deny"

# Empty [] = Good to go!
# Messages = Fix these issues first
```

This policy acts like **spell-check for infrastructure** - catching problems before they become expensive mistakes!

    

Understanding the Query Structure
"data.terraform.gcp.deny" breaks down as:   

data = OPA's root namespace for all loaded policies
terraform.gcp = the package name from your policy (package terraform.gcp)
deny = the specific rule you want to evaluate

Complete Command Workflow
bash# Step 1: Generate Terraform plan
terraform plan -out=tfplan

# Step 2: Convert plan to JSON format
terraform show -json tfplan > tfplan.json

# Step 3: Check if your plan passes the policy
opa eval -d policy.rego -i tfplan.json "data.terraform.gcp.deny"

# Empty [] = Good to go!
# Messages = Fix these issues first
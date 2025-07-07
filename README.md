# Rego Policy Explanation - Simple Notes

## What is this file?
This is a **Rego policy file** that acts like a security guard for your Terraform configurations. It checks your infrastructure code BEFORE you deploy it to catch problems early.

---

### 0. Create a GCP Service Account and Download Credentials

1. **Go to the [Google Cloud Console](https://console.cloud.google.com/)**
2. **Create a Service Account**
    - Go to **IAM & Admin → Service Accounts**
    - Click **Create Service Account**
    - Name it `terraform-sa`
3. **Assign Owner Role (for testing only)**
    - Grant the **Owner** role to the service account (for initial setup; you can restrict permissions later)
4. **Download the Key File**
    - After creation, go to the **Keys** tab for your service account
    - Click **Add Key → Create new key → JSON**
    - Download the key file and rename it to `key.json`
    - Place `key.json` in a safe location for use with this repository

---    

## 🚀 How to Use This Repo

You can use this repo both locally (on your machine) and as part of a CI/CD pipeline on GitHub Actions. Start with local checks to ensure everything works, then move to automated checks in the cloud!

---

### 1. Clone the Repository

```bash
git clone https://github.com/anudishu/opa-gcp-code.git
cd opa-gcp-code
```

---

### 2. Prepare Your `terraform.tfvars`

Create a `terraform.tfvars` file in the root directory with the following variables (replace values as needed):

```hcl
project_id              = "your-gcp-project-id"
region                  = "your-gcp-region"
zone                    = "your-gcp-zone"
google_credentials_file = "path/to/your/key.json"
```

- **project_id**: Your GCP project ID  
- **region**: e.g. "us-central1"  
- **zone**: e.g. "us-central1-a"  
- **google_credentials_file**: Path to your Google Cloud service account JSON credentials

---

## 🖥️ Local OPA Policy Check (Before Using GitHub Actions)

This is the best way to test and understand the policy before automating!

#### 1. Install Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [OPA CLI](https://www.openpolicyagent.org/docs/latest/#running-opa)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) (optional, for authentication)

#### 2. Generate and Inspect Terraform Plan

```bash
terraform init
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
```

#### 3. Run OPA Policy Evaluation

```bash
opa eval -d policy.rego -i tfplan.json "data.terraform.gcp.deny"
```

- **Empty output (`[]`)**: All policies passed, you can safely deploy! ✅
- **One or more error messages**: Policy violation detected, deployment will be stopped until fixed. ❌

#### 4. Provision Infrastructure (only if OPA returns empty list)

```bash
terraform apply
```

---

## 🤖 GitHub Actions: Automated Policy Enforcement

Once you have validated things locally, you can enforce policies in your CI/CD pipeline using GitHub Actions.

### 1. Add Service Account Credentials as a GitHub Secret

1. Go to your repo on GitHub → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret**.
3. Name it `SA`.
4. Paste the contents of your service account JSON file.
5. In your workflow, refer to the secret like:  
   ```yaml
   ${{ secrets.SA }}
   ```

### 2. Example GitHub Actions Workflow

Create a file like `.github/workflows/opa-terraform.yml`:

```yaml
name: Terraform Plan and OPA Policy Check

on:
  pull_request:
    paths:
      - '**.tf'
      - 'policy.rego'
      - '.github/workflows/opa-terraform.yml'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Install OPA
        run: |
          curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
          chmod +x opa
          sudo mv opa /usr/local/bin/

      - name: Write GCP Credentials
        run: echo "${{ secrets.SA }}" > "${{ github.workspace }}/gcp-sa.json"

      - name: Terraform Init
        run: terraform init

      - name: Terraform Plan
        run: terraform plan -out=tfplan

      - name: Terraform Show (to JSON)
        run: terraform show -json tfplan > tfplan.json

      - name: OPA Policy Check
        run: |
          opa eval -d policy.rego -i tfplan.json "data.terraform.gcp.deny" > opa_result.txt
          cat opa_result.txt
          if grep -q '\[' opa_result.txt && ! grep -q '\[\]' opa_result.txt; then
            echo "Policy violations found! Failing the job."
            exit 1
          fi

      # Optional: Only apply on merge to main, and if OPA passes!
```

---

## 💡 When Does OPA Stop or Allow Deployment?

- **OPA stops deployment** when any resource in your plan violates a policy (e.g., using non-e2-micro VM, leaving bucket versioning off, allowing SSH from internet, etc.).
- **OPA allows deployment** only if all checks pass (OPA returns an empty array).

---

## 📝 Example Workflow (CI/CD)

1. **Clone repo** and set up your `terraform.tfvars`.
2. **Store GCP credentials** securely as a GitHub secret named `SA`.
3. **CI/CD workflow** runs `terraform plan` → exports plan as JSON → runs OPA policy check.
4. **Deployment proceeds** only if OPA check passes.

---

## File Structure Breakdown

### 1. Header Section

```rego
package terraform.gcp
import rego.v1
```

- **package**: Like a folder name - organizes your rules
- **import rego.v1**: Uses the latest Rego language features

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

---

## How it Works (Simple Flow)

1. **Input**: Your Terraform plan (what you want to build)
2. **Process**: Rego checks each resource against the rules
3. **Output**:
   * `[]` = All good, deploy away! ✅
   * `["error message"]` = Stop! Fix the issues first ❌

---

## Key Concepts

| Term              | Simple Explanation                  |
|-------------------|-------------------------------------|
| `deny`            | Rules that BLOCK deployment         |
| `contains msg if` | "If this condition is true, show this error message" |
| `resource_changes[_]` | "Check every resource in the plan" |
| `0.0.0.0/0`       | "The entire internet" (security risk) |

---

## Benefits for Your Team

- **Catch mistakes early** - Before they cost money
- **Enforce standards** - Everyone follows the same rules
- **Improve security** - Automatic security checks
- **Save time** - No manual reviews needed

---

## Quick Command Reference

```bash
# Check if your plan passes the policy
opa eval -d policy.rego -i tfplan.json "data.terraform.gcp.deny"

# Empty [] = Good to go!
# Messages = Fix these issues first
```

This policy acts like **spell-check for infrastructure** - catching problems before they become expensive mistakes!

---

## Understanding the Query Structure

"data.terraform.gcp.deny" breaks down as:   

- data = OPA's root namespace for all loaded policies
- terraform.gcp = the package name from your policy (package terraform.gcp)
- deny = the specific rule you want to evaluate

---

## Complete Command Workflow

```bash
# Step 1: Generate Terraform plan
terraform plan -out=tfplan

# Step 2: Convert plan to JSON format
terraform show -json tfplan > tfplan.json

# Step 3: Check if your plan passes the policy
opa eval -d policy.rego -i tfplan.json "data.terraform.gcp.deny"

# Empty [] = Good to go!
# Messages = Fix these issues first
```

---
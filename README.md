# GCP Temporary Access Terraform Module

A Terraform module for granting temporary access to Google Cloud Platform (GCP) projects for Gemini Cloud Assist functionality. This module provisions the necessary IAM permissions and enables required APIs following Terraform best practices.

## Overview

This module simplifies the process of granting a Google Group temporary access to a GCP project with the appropriate permissions for Gemini Cloud Assist. It handles:

- IAM role assignments for viewer and Gemini Cloud Assist permissions
- Enabling the Gemini Cloud Assist API
- Configurable API cleanup behavior on resource destruction
- Input validation to catch configuration errors early
- API-first apply flow to avoid IAM creation before required services are on

## Prerequisites

Before using this module, ensure you have:

1. **Terraform Installation**: Terraform >= 1.5.0 installed on your system
2. **GCP Project**: An existing GCP project where you want to grant access
3. **Google Group**: A valid Google Group email address that will receive the permissions
4. **GCP Permissions**: The account running Terraform must have the following IAM roles on the target project:
   - `roles/resourcemanager.projectIamAdmin` - Required to grant IAM roles to the group
   - `roles/serviceusage.serviceUsageAdmin` - Required to enable the Gemini Cloud Assist API
5. **Google Provider Authentication**: Configured authentication for the Google provider (see Provider Configuration section)

## Usage

### Basic Usage with tfvars File

1. Copy the example tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values:
```hcl
project_id = "my-gcp-project-id"
group_id   = "gemini-access@example.com"
```

3. Run Terraform:
```bash
# Initialize Terraform and download providers
terraform init

# Preview the changes that will be made
terraform plan

# Apply the configuration to grant access
terraform apply
```

### Usage with Environment Variables

Set variables using the `TF_VAR_` prefix:

```bash
export TF_VAR_project_id="my-gcp-project-id"
export TF_VAR_group_id="gemini-access@example.com"
export TF_VAR_disable_on_destroy="true"

terraform init
terraform plan
terraform apply
```

### Usage with CLI Flags

Pass variables directly via command-line flags:

```bash
terraform init

terraform plan \
  -var="project_id=my-gcp-project-id" \
  -var="group_id=gemini-access@example.com" \
  -var="disable_on_destroy=true"

terraform apply \
  -var="project_id=my-gcp-project-id" \
  -var="group_id=gemini-access@example.com"
```

### Complete Workflow Example

```bash
# 1. Initialize the Terraform working directory
terraform init

# 2. Validate the configuration
terraform validate

# 3. Format the code (optional)
terraform fmt

# 4. Preview changes
terraform plan -out=tfplan

# 5. Apply the changes
terraform apply tfplan

# 6. View outputs
terraform output

# 7. When access is no longer needed, remove the resources (cleanly rolls back permissions)
terraform destroy
```
> Rollback tip: if you need to revoke access immediately without destroying state, you can also set `disable_on_destroy = true` (default) and run `terraform destroy -target=google_project_iam_member.gemini_roles -target=google_project_service.gemini_cloud_assist_api` to remove only this module’s grants and API enablement.

### Fast Path with Make (interactive)

For support engineers working from a Zendesk ticket, use the helper to collect values, create `terraform.tfvars`, run a plan, and optionally apply:

```bash
make interactive
```

You’ll be prompted for:
- Zendesk ticket ID (required) to auto-set the group email as `ticket-<ID>@cre.doit-intl.com`
- GCP `project_id`
- Whether to disable the API on destroy (`true`/`false`, default `true`)

If you prefer manual commands after generating `terraform.tfvars`, you can still run:

```bash
make plan   # or terraform plan -var-file=terraform.tfvars
make apply  # or terraform apply -var-file=terraform.tfvars
make destroy
```

## Inputs

| Name | Description | Type | Default | Required | Validation |
|------|-------------|------|---------|----------|------------|
| `project_id` | The ID of the GCP project to grant access to | `string` | n/a | yes | Must not be empty |
| `group_id` | The email address of the Google Group to grant access to (e.g., team@example.com) | `string` | n/a | yes | Must be a valid email address format |
| `disable_on_destroy` | Whether to disable the Gemini Cloud Assist API when the resource is destroyed. Set to true to disable the API on destroy (recommended for temporary access), or false to keep the API enabled after resource destruction. | `bool` | `true` | no | n/a |

## Outputs

| Name | Description |
|------|-------------|
| `project_id` | The GCP project ID where access was granted |
| `group_id` | The Google Group email address that was granted access |
| `iam_member_ids` | Map of role names to their IAM member resource IDs for tracking the granted permissions. Keys: `viewer`, `user`, `investigation_user` |
| `api_service_id` | The ID of the enabled Gemini Cloud Assist API service resource |

## Provider Configuration

### Authentication Methods

The Google provider supports multiple authentication methods. Choose the one that fits your workflow:

#### 1. Application Default Credentials (Recommended for local development)

```bash
gcloud auth application-default login
```

Then configure the provider in your Terraform configuration:

```hcl
provider "google" {
  project = var.project_id
}
```

#### 2. Service Account Key File

```hcl
provider "google" {
  credentials = file("path/to/service-account-key.json")
  project     = var.project_id
}
```

#### 3. Service Account Impersonation

```hcl
provider "google" {
  impersonate_service_account = "terraform@my-project.iam.gserviceaccount.com"
  project                     = var.project_id
}
```

#### 4. Environment Variable

```bash
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
terraform apply
```

### Provider Version

This module requires the Google provider version >= 5.0.0 and < 6.0.0. The version constraint is defined in `versions.tf` and will be automatically enforced when you run `terraform init`.

## Roles Granted

This module grants the following IAM roles to the specified Google Group:

- `roles/viewer` - Provides read-only access to all project resources
- `roles/geminicloudassist.user` - Enables basic Gemini Cloud Assist functionality
- `roles/geminicloudassist.investigationUser` - Enables investigation features in Gemini Cloud Assist

Roles are managed via a single, loop-based resource to keep state tidy and simplify rollbacks.

## Important Notes

### IAM Propagation Delays

After applying this module, there may be a delay of up to 2 minutes before the IAM permissions are fully propagated across all GCP services. If users in the group experience permission errors immediately after applying, wait a few minutes and try again.

### API Enablement Behavior

- The module enables the `geminicloudassist.googleapis.com` API on the target project
- By default (`disable_on_destroy = true`), the API will be disabled when you run `terraform destroy`
- If you set `disable_on_destroy = false`, the API will remain enabled even after destroying the Terraform resources
- If the API is already enabled in your project, Terraform will import it into the state without making changes
- IAM grants are created only after the API is enabled, reducing transient failures during apply

### State Management

For production use, it's recommended to:
- Use a remote backend (e.g., GCS, S3) to store Terraform state
- Enable state locking to prevent concurrent modifications
- Use separate workspaces or state files for different environments

## Troubleshooting

### Error: "The project_id must not be empty"

**Cause**: The `project_id` variable was not provided or is an empty string.

**Solution**: Ensure you've set the `project_id` variable in your tfvars file, environment variable, or CLI flag.

### Error: "The group_id must be a valid email address"

**Cause**: The `group_id` variable is not in a valid email format.

**Solution**: Provide a valid Google Group email address (e.g., `team@example.com`).

### Error: "Permission denied" or "Insufficient permissions"

**Cause**: The account running Terraform lacks the required IAM permissions.

**Solution**: Ensure your account or service account has:
- `roles/resourcemanager.projectIamAdmin` on the target project
- `roles/serviceusage.serviceUsageAdmin` on the target project

You can grant these roles using:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:YOUR_EMAIL" \
  --role="roles/resourcemanager.projectIamAdmin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:YOUR_EMAIL" \
  --role="roles/serviceusage.serviceUsageAdmin"
```

### Error: "Group does not exist"

**Cause**: The specified group email does not exist in your Google Workspace organization.

**Solution**: Create the group in Google Workspace Admin Console or verify the email address is correct.

### Error: "API not enabled" or "Service not found"

**Cause**: The Gemini Cloud Assist API may not be available in your project's region or organization.

**Solution**: Verify that:
- Your project has access to Gemini Cloud Assist services
- The API is available in your organization
- Your project is not restricted by organizational policies

### Changes Not Detected After Initial Apply

**Cause**: This is expected behavior - Terraform is idempotent.

**Solution**: No action needed. If no changes are detected, it means your infrastructure matches the desired state.

### API Still Enabled After Destroy

**Cause**: The `disable_on_destroy` variable is set to `false`.

**Solution**: If you want the API to be disabled on destroy, set `disable_on_destroy = true` before running `terraform destroy`.

## License

This module is provided as-is for use in granting temporary access to GCP projects.

## Contributing

When contributing to this module, please ensure:
- All code is formatted with `terraform fmt`
- Variables include validation rules where appropriate
- Changes are documented in this README
- Examples are tested and working

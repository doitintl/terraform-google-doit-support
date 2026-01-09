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
3. **Zendesk Ticket Number**: The number of your DoiT support ticket
4. **GCP Permissions**: The account running Terraform must have the following IAM roles on the target project:
   - `roles/resourcemanager.projectIamAdmin` - Required to grant IAM roles to the group
   - `roles/serviceusage.serviceUsageAdmin` - Required to enable the Gemini Cloud Assist API
5. **Google Provider Authentication**: Configured authentication for the Google provider (see Provider Configuration section)

## Usage

The support agent assigned to your ticket will provide you with the correct module call. It will look something like this:

```terraform
module "fde_terraform_cloud_assist" {
  source        = "doitintl/fde-terraform-cloud-assist"
  project_id    = "my-gcp-project-id"
  ticket_number = 123456
}
```

You can run `terraform plan` to see the changes that will be made.

If you are satisfied with the changes, run `terraform apply` to apply the changes.

When you are done, run `terraform destroy` to remove the resources.

Please note that the module will not disable the Gemini Cloud Assist API when the resource is destroyed. If you want to disable the API after resource destruction, set `disable_on_destroy = true`.

When the ticket is closed, the Google Group will automatically be deleted on our side as well.

## Provider Configuration

### Authentication Methods

The Google provider supports multiple authentication methods. Please refer to the [Google provider documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference) for more information.

## Roles Granted

This module grants the following IAM roles to the Google group assigned to your support ticket:

- `roles/viewer` - Provides read-only access to all project resources
- `roles/geminicloudassist.user` - Enables basic Gemini Cloud Assist functionality
- `roles/geminicloudassist.investigationUser` - Enables investigation features in Gemini Cloud Assist

The group already exists and is managed by DoiT support.

## Important Notes

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

**Solution**: Ensure you've set the `project_id` variable when calling the module. This is usually the project ID that you specified when opening the ticket and it should already be set in the module call that has been provided to you by DoiT support.

### Error: "The ticket_number must be a valid number"

**Cause**: The `ticket_number` variable is not a valid number.

**Solution**: Provide a valid ticket number (e.g., `123456`). This is usually the the number that was assigned to your ticket and it should already be set in the module call that has been provided to you by DoiT support.

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

**Cause**: The specified group email does not exist in our Google Workspace organization.

**Solution**: This is an error on our side. Please contact DoiT support to resolve this issue.

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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_project_iam_member.gemini_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_service.gemini_cloud_assist_api](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_disable_on_destroy"></a> [disable\_on\_destroy](#input\_disable\_on\_destroy) | Whether to disable the Gemini Cloud Assist API when the resource is destroyed. Set to true to disable the API on destroy, or false to keep the API enabled after resource destruction. | `bool` | `false` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The ID of the GCP project to grant access to | `string` | n/a | yes |
| <a name="input_ticket_number"></a> [ticket\_number](#input\_ticket\_number) | The number of your DoiT support ticket | `number` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_service_id"></a> [api\_service\_id](#output\_api\_service\_id) | The ID of the enabled Gemini Cloud Assist API service resource |
| <a name="output_group_id"></a> [group\_id](#output\_group\_id) | The Google Group email address that was granted access |
| <a name="output_iam_member_ids"></a> [iam\_member\_ids](#output\_iam\_member\_ids) | Map of role names to their IAM member resource IDs for tracking the granted permissions |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The GCP project ID where access was granted |
<!-- END_TF_DOCS -->

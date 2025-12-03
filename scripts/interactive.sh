#!/usr/bin/env bash
set -euo pipefail

# Interactive helper to collect variables, create terraform.tfvars,
# and optionally run plan/apply for the Gemini Cloud Assist module.

cd "$(dirname "$0")/.."

TF=${TF:-terraform}
TFVARS=${TFVARS:-terraform.tfvars}

prompt_default() {
  local prompt="$1"
  local default="$2"
  local value
  read -r -p "$prompt" value
  echo "${value:-$default}"
}

echo "=== Gemini Cloud Assist Terraform helper ==="

zendesk_ticket=$(prompt_default "Zendesk ticket ID (required): " "${ZENDESK_TICKET_ID:-}")
if [[ -z "$zendesk_ticket" ]]; then
  echo "Zendesk ticket ID is required to continue."
  exit 1
fi

group_id="ticket-${zendesk_ticket}@cre.doit-intl.com"

project_id=$(prompt_default "Project ID: " "${TF_VAR_project_id:-}")
if [[ -z "$project_id" ]]; then
  echo "Project ID is required."
  exit 1
fi

disable_default="${TF_VAR_disable_on_destroy:-true}"
read -r -p "Disable API on destroy? [true/false] (default: ${disable_default}): " disable_input
disable_on_destroy="${disable_input:-$disable_default}"
if [[ "$disable_on_destroy" != "true" && "$disable_on_destroy" != "false" ]]; then
  echo "disable_on_destroy must be true or false"
  exit 1
fi

cat > "${TFVARS}" <<EOF
project_id = "${project_id}"
group_id = "${group_id}"
disable_on_destroy = ${disable_on_destroy}
EOF

echo "Wrote variables to ${TFVARS}"

${TF} init -input=false
${TF} plan -input=false -var-file="${TFVARS}" -out=tfplan

read -r -p "Apply this plan now? [y/N]: " apply_now
if [[ "${apply_now}" =~ ^[Yy]$ ]]; then
  ${TF} apply -input=false tfplan
else
  echo "Skipping apply. Plan saved to tfplan."
fi

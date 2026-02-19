#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
set -o errexit

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -euo pipefail

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

source "${grand_parent_directory}/deploy_utils.sh"
source "${parent_directory}/helper.sh"

if [ -n "${GITHUB_ACTIONS+x}" ]; then
	PLATFORM="github"
	OUTPUT_DIR="${GITHUB_WORKSPACE:-${grand_parent_directory}}"
else
	PLATFORM="devops"
	OUTPUT_DIR="${BUILD_REPOSITORY_LOCALPATH}"
fi

app_resource_id=$(az graph query -q "Resources | join kind=leftouter (ResourceContainers | where type=='microsoft.resources/subscriptions' | project subscription=name, subscriptionId) on subscriptionId | where name == '$APP_SERVICE_NAME' | project id, name, subscription" --query data[0].id --output tsv)
app_service_resource_group=$(echo "$app_resource_id" | cut -d '/' -f 5)
app_service_subscription=$(echo "$app_resource_id" | cut -d '/' -f 3)
output_file="${OUTPUT_DIR}/Web Application Configuration.md"
{
printf "Configure the Web Application authentication using the following script.\n" >"${output_file}"
printf "\n\n" >>"${output_file}"
printf "**Configure authentication**\n" >>"${output_file}"

printf "\n\n" >>"${output_file}"

printf "az ad app update --id %s --web-home-page-url https://%s.azurewebsites.net --web-redirect-uris https://%s.azurewebsites.net/ https://%s.azurewebsites.net/.auth/login/aad/callback\n\n" "$APP_REGISTRATION_APP_ID" "$APP_SERVICE_NAME" "$APP_SERVICE_NAME" "$APP_SERVICE_NAME" >>"${output_file}"

printf "\n" >>"${output_file}"
printf "az role assignment create --assignee %s --role reader --subscription %s --scope /subscriptions/%s\n" "$APP_REGISTRATION_APP_ID" "$ARM_SUBSCRIPTION_ID" "$ARM_SUBSCRIPTION_ID" >>"${output_file}"

printf "\n" >>"${output_file}"
printf "\n" >>"${output_file}"
printf "**Assign permissions**\n" >>"${output_file}"

printf "\n" >>"${output_file}"
printf "\n" >>"${output_file}"
printf "az rest --method POST --uri \"https://graph.microsoft.com/beta/applications/%s/federatedIdentityCredentials\" --body \"{'name': 'ManagedIdentityFederation', 'issuer': 'https://login.microsoftonline.com/%s/v2.0', 'subject': '%s', 'audiences': [ 'api://AzureADTokenExchange' ]}\"" "$APP_REGISTRATION_OBJECTID" "$ARM_TENANT_ID" "$ARM_OBJECT_ID" >>"${output_file}"
printf "\n" >>"${output_file}"

printf "az webapp restart --name %s  --resource-group %s --subscription %s \n\n" "$APP_SERVICE_NAME" "$app_service_resource_group" "$app_service_subscription" >>"${output_file}"
printf "\n\n" >>"${output_file}"

printf "[Access the Web App](https://%s.azurewebsites.net) \n\n" "$APP_SERVICE_NAME" >>"${output_file}"
} >>"${output_file}"

if [ "$PLATFORM" == "github" ]; then
	cat "${output_file}" >>"${GITHUB_STEP_SUMMARY}"
else
	echo "##vso[task.uploadsummary]${output_file}"
fi
exit 0


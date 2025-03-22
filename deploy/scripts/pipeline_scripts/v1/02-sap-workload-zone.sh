#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
top_directory="$(dirname "$parent_directory")"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${parent_directory}/deploy_utils.sh"
source "${script_directory}/helper.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	set -o errexit
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG

set -eu

echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

if [ ! -f "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $WORKLOAD_ZONE_TFVARS_FILENAME was not found ---$reset"
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
	exit 2
fi

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

	if ! printenv ARM_SUBSCRIPTION_ID; then
		echo "##vso[task.logissue type=error]Variable WL_ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if ! printenv ARM_CLIENT_ID; then
		echo "##vso[task.logissue type=error]Variable WL_ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if ! printenv ARM_CLIENT_SECRET; then
		echo "##vso[task.logissue type=error]Variable WL_ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if ! printenv ARM_TENANT_ID; then
		echo "##vso[task.logissue type=error]Variable WL_ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_SUBSCRIPTION_ID" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_SUBSCRIPTION_ID was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_CLIENT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_CLIENT_ID was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_CLIENT_SECRET" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_CLIENT_SECRET was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$CP_ARM_TENANT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable CP_ARM_TENANT_ID was not defined in the $PARENT_VARIABLE_GROUP variable group."
		exit 2
	fi
fi

#
# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$TF_VERSION"
	echo -e "$green--- az login ---$reset"
	LogonToAzure false
fi
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

# Print the execution environment details
print_header

echo -e "$green--- Read deployment details ---$reset"
dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr 'A-Z' 'a-z' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME")

NETWORK_IN_FILENAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | awk -F'-' '{print $3}')

echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Network:                             $NETWORK"

echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network(filename):                   $NETWORK_IN_FILENAME"

echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
echo "Workload TFvars                      $WORKLOAD_ZONE_TFVARS_FILENAME"
echo ""

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The environment setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$ENVIRONMENT' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$LOCATION' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The network_logical_name setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$NETWORK' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$CONTROL_PLANE_NAME"
echo "Deployer Environment File:           $deployer_environment_file_name"
if [ ! -f "${deployer_environment_file_name}" ]; then
	echo -e "$bold_red--- $CONTROL_PLANE_NAME was not found ---$reset"
	echo "##vso[task.logissue type=error]Control plane configuration file $CONTROL_PLANE_NAME was not found."
	exit 2
fi
workload_zone_name="${ENVIRONMENT}-${LOCATION_CODE_IN_FILENAME}-${NETWORK}"
echo "Workload Zone Name:                  $workload_zone_name"
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$workload_zone_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none

if ! az extension list --query "[?contains(name, 'azure-devops')]" --output table; then
	az extension add --name azure-devops --output none --only-show-errors
fi
az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none

PARENT_VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$PARENT_VARIABLE_GROUP'].id | [0]")

if [ -z "${PARENT_VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP could not be found."
	exit 2
fi
export PARENT_VARIABLE_GROUP_ID

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi
export VARIABLE_GROUP_ID

az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "CONTROL_PLANE_NAME.value")
if [ -z "${az_var}" ]; then
	az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name CONTROL_PLANE_NAME --value "$CONTROL_PLANE_NAME" --output none --only-show-errors
else
	az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name CONTROL_PLANE_NAME --value "$CONTROL_PLANE_NAME" --output none --only-show-errors
fi

GROUP_ID=0
if get_variable_group_id "$VARIABLE_GROUP" ;
then
	VARIABLE_GROUP_ID=$GROUP_ID
else
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

echo -e "$green--- Read parameter values ---$reset"

dos2unix -q "${deployer_environment_file_name}"

landscape_tfstate_key="${WORKLOAD_ZONE_FOLDERNAME}.terraform.tfstate"
export landscape_tfstate_key
deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export deployer_tfstate_key

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "${CONTROL_PLANE_NAME}")
	if [ -z "$key_vault_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	workload_key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${workload_zone_name}_KeyVaultName" "${workload_zone_name}")
	az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_ID.value")
	if [ -z "${az_var}" ]; then
		az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name APPLICATION_CONFIGURATION_ID --value "$APPLICATION_CONFIGURATION_ID" --output none --only-show-errors
	else
		az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name APPLICATION_CONFIGURATION_ID --value "$APPLICATION_CONFIGURATION_ID" --output none --only-show-errors
	fi
else
	echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	load_config_vars "${workload_environment_file_name}" "keyvault"
	key_vault="$keyvault"
	load_config_vars "${workload_environment_file_name}" "tfstate_resource_id"
	key_vault_id=$(az resource list --name "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
fi

if [ -z "$key_vault" ]; then
	echo "##vso[task.logissue type=error]Key vault name (${CONTROL_PLANE_NAME}_KeyVaultName) was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	exit 2
fi

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	exit 2
fi

export TF_VAR_spn_keyvault_id=${key_vault_id}

REMOTE_STATE_SA=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
REMOTE_STATE_RG=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
STATE_SUBSCRIPTION=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export REMOTE_STATE_SA
export REMOTE_STATE_RG
export STATE_SUBSCRIPTION
export tfstate_resource_id

export workload_key_vault

echo "Deployer state filename:             $deployer_tfstate_key"
echo "Target subscription                  $WL_ARM_SUBSCRIPTION_ID"

echo "Terraform statefile subscription:    $STATE_SUBSCRIPTION"
echo "Terraform statefile storage account: $REMOTE_STATE_SA"

if [ -n "$key_vault" ]; then
	echo "Deployer Key Vault:                  ${key_vault}"
else
	echo "Deployer Key Vault:                  undefined"
fi

if [ -n "$workload_key_vault" ]; then
	echo "Workload Key vault:                  ${workload_key_vault}"
else
	echo "Workload Key vault:                  undefined"
fi

secrets_set=1
az account set --subscription $STATE_SUBSCRIPTION
echo -e "$green --- Set secrets ---$reset"

if [ "$USE_MSI" != "true" ]; then
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --workload --vault "${key_vault}" --environment "${ENVIRONMENT}" \
		--region "${LOCATION}" --subscription "$WL_ARM_SUBSCRIPTION_ID" --spn_id "$WL_ARM_CLIENT_ID" --spn_secret "${WL_ARM_CLIENT_SECRET}" \
		--tenant_id "$WL_ARM_TENANT_ID" --keyvault_subscription "$STATE_SUBSCRIPTION"
else
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --workload --vault "${key_vault}" --environment "${ENVIRONMENT}" \
		--region "${LOCATION}" --subscription "$WL_ARM_SUBSCRIPTION_ID" --keyvault_subscription "$STATE_SUBSCRIPTION" --msi
fi
secrets_set=$?
echo "Set Secrets returned: $secrets_set"

echo -e "$green--- Set Permissions ---$reset"

if [ "$USE_MSI" != "true" ]; then

	isUserAccessAdmin=$(az role assignment list --role "User Access Administrator" --subscription "$STATE_SUBSCRIPTION" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --output tsv)

	if [ -n "${isUserAccessAdmin}" ]; then

		echo -e "$green--- Set permissions ---$reset"
		perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Reader" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --output tsv --only-show-errors)
		if [ -z "$perms" ]; then
			echo -e "$green --- Assign subscription permissions to $perms ---$reset"
			az role assignment create --assignee "$ARM_OBJECT_ID" --role "Reader" --scope "/subscriptions/${STATE_SUBSCRIPTION}" --output none
		fi

		resource_group_id=$(az group show --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" query "id" -o tsv)
		perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Storage Blob Data Contributor" --scope "${resource_group_id}" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --only-show-errors)
		if [ -z $perms ]; then
			echo "Assigning Storage Blob Data Contributor permissions for $ARM_OBJECT_ID to ${resource_group_id}"
			az role assignment create --assignee "$ARM_OBJECT_ID" --role "Storage Blob Data Contributor" --scope "${resource_group_id}" --output none
		fi

		perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Storage Blob Data Contributor" --scope "${tfstate_resource_id}" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --only-show-errors)
		if [ -z "$perms" ]; then
			echo "Assigning Storage Blob Data Contributor permissions for $ARM_OBJECT_ID to ${tfstate_resource_id}"
			az role assignment create --assignee "$ARM_OBJECT_ID" --role "Storage Blob Data Contributor" --scope "${tfstate_resource_id}" --output none
		fi

		resource_group_name=$(az resource show --id "${tfstate_resource_id}" --query resourceGroup -o tsv)

		if [ -n "$resource_group_name" ]; then
			for scope in $(az resource list --resource-group "${resource_group_name}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Network/privateDnsZones --query "[].id" --output tsv); do
				perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Private DNS Zone Contributor" --scope "$scope" --assignee "$ARM_OBJECT_ID" --query "[].principalName | [0]" --output tsv --only-show-errors)
				if [ -z $perms ]; then
					echo "Assigning DNS Zone Contributor permissions for $ARM_OBJECT_ID to ${scope}"
					az role assignment create --assignee "$ARM_OBJECT_ID" --role "Private DNS Zone Contributor" --scope "$scope" --output none
				fi
			done
		fi

		resource_group_name=$(az keyvault show --name "${key_vault}" --query resourceGroup --subscription "$STATE_SUBSCRIPTION" -o tsv)

		if [ -n "${resource_group_name}" ]; then
			resource_group_id=$(az group show --name "${resource_group_name}" --subscription "$STATE_SUBSCRIPTION" --query id -o tsv)

			vnet_resource_id=$(az resource list --resource-group "${resource_group_name}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Network/virtualNetworks -o tsv --query "[].id | [0]")
			if [ -n "${vnet_resource_id}" ]; then
				perms=$(az role assignment list --subscription "$STATE_SUBSCRIPTION" --role "Network Contributor" --scope "$vnet_resource_id" --query "[].principalName | [0]" --assignee "$ARM_OBJECT_ID" --output tsv --only-show-errors)

				if [ -z $perms ]; then
					echo "Assigning Network Contributor rights for $ARM_OBJECT_ID to ${vnet_resource_id}"
					az role assignment create --assignee "$ARM_OBJECT_ID" --role "Network Contributor" --scope "$vnet_resource_id" --output none
				fi
			fi
		fi
	else
		echo " ##vso[task.logissue type=warning]Service Principal $WL_ARM_CLIENT_ID does not have 'User Access Administrator' permissions. Please ensure that the service principal $WL_ARM_CLIENT_ID has permissions on the Terrafrom state storage account and if needed on the Private DNS zone and the source management network resource"
	fi
fi

echo -e "$green--- Deploy the workload zone ---$reset"
cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

# Set logon variables
ARM_CLIENT_ID="$WL_ARM_CLIENT_ID"
export ARM_CLIENT_ID
ARM_CLIENT_SECRET="$WL_ARM_CLIENT_SECRET"
export ARM_CLIENT_SECRET
ARM_TENANT_ID=$WL_ARM_TENANT_ID
export ARM_TENANT_ID
ARM_SUBSCRIPTION_ID=$WL_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	echo -e "$green--- az login ---$reset"
	LogonToAzure false
else
	LogonToAzure "$USE_MSI"
fi
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/install_workloadzone.sh" --parameterfile "$WORKLOAD_ZONE_TFVARS_FILENAME" \
	--deployer_environment "$CONTROL_PLANE_NAME" --subscription "$WL_ARM_SUBSCRIPTION_ID" \
	--deployer_tfstate_key "${deployer_tfstate_key}" --keyvault "${key_vault}" --storageaccountname "${REMOTE_STATE_SA}" \
	--state_subscription "${STATE_SUBSCRIPTION}" \
	--application_configuration_id "${APPLICATION_CONFIGURATION_ID}" \
	--auto-approve --ado --msi; then
	echo "##vso[task.logissue type=warning]Workload zone deployment completed successfully."
else
	return_code=$?
	echo "##vso[task.logissue type=error]Workload zone deployment failed."
	exit 1
fi

echo "Return code from deployment:         ${return_code}"
cd "$CONFIG_REPO_PATH" || exit

workload_prefix="${ENVIRONMENT}-${LOCATION_CODE_IN_FILENAME}-${NETWORK}"

az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "FENCING_SPN_ID.value")
if [ -z "${az_var}" ]; then
	echo "##vso[task.logissue type=warning]Variable FENCING_SPN_ID is not set. Required for highly available deployments when using Service Principals for fencing."
else
	fencing_id=$(az keyvault secret list --vault-name "$workload_key_vault" --subscription "$STATE_SUBSCRIPTION" --query [].name -o tsv | grep "${workload_prefix}-fencing-spn-id" | xargs || true)
	if [ -z "$fencing_id" ]; then
		az keyvault secret set --name "${workload_prefix}-fencing-spn-id" --vault-name "$workload_key_vault" --value "$FENCING_SPN_ID" --subscription "$STATE_SUBSCRIPTION" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
		az keyvault secret set --name "${workload_prefix}-fencing-spn-pwd" --vault-name "$workload_key_vault" --value="$FENCING_SPN_PWD" --subscription "$STATE_SUBSCRIPTION" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
		az keyvault secret set --name "${workload_prefix}-fencing-spn-tenant" --vault-name "$workload_key_vault" --value "$FENCING_SPN_TENANT" --subscription "$STATE_SUBSCRIPTION" --expires "$(date -d '+1 year' -u +%Y-%m-%dT%H:%M:%SZ)" --output none
	fi
fi

set +o errexit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"

cd "$CONFIG_REPO_PATH" || exit
# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

added=0

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
normalizedName=$(echo "${workload_prefix}" | tr -d '-')

if [ -f "${workload_prefix}.md" ]; then

	mv "${workload_prefix}.md" "${normalizedName}.md"
	git add "${normalizedName}.md"
	# echo "##vso[task.uploadsummary]./${normalizedName}.md"
	added=1
fi

if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	git add -f "$WORKLOAD_ZONE_TFVARS_FILENAME"
	added=1
fi

if [ -f "/.terraform/terraform.tfstate" ]; then
	git add -f "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
fi

if [ 1 == $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER of $WORKLOAD_ZONE_FOLDERNAME [skip ci]"
	if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Workload deployment $WORKLOAD_ZONE_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi

fi

exit $return_code

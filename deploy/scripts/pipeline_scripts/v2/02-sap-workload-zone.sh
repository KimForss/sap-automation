#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"


#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"

#call stack has full scriptname when using source
source "${parent_directory}/helper.sh"
DEBUG=False


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

tfvarsFile="SYSTEM/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/SYSTEM/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $WORKLOAD_ZONE_TFVARS_FILENAME was not found ---$reset"
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
	exit 2
fi

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
fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$(tf_version)" || true
	echo -e "$green--- az login ---$reset"
	LogonToAzure false || true
else
	LogonToAzure "$USE_MSI" || true
fi
return_code=$?
if [ 0 != $return_code ]; then
	echo -e "$bold_red--- Login failed ---$reset"
	echo "##vso[task.logissue type=error]az login failed."
	exit $return_code
fi
az account set --subscription "$ARM_SUBSCRIPTION_ID"

echo -e "$green--- Read deployment details ---$reset"
dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

WORKLOAD_ZONE_NAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | cut -d'-' -f1-3)
landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key

echo "Workload zone TFvars:                $WORKLOAD_ZONE_TFVARS_FILENAME"
echo "Environment:                         $ENVIRONMENT"
echo "CONTROL_PLANE_NAME:                  $CONTROL_PLANE_NAME"
echo "WORKLOAD_ZONE_NAME:                  $WORKLOAD_ZONE_NAME"
echo "Location:                            $LOCATION"
echo "Network:                             $NETWORK"

echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network(filename):                   $NETWORK_IN_FILENAME"

echo ""

echo "Agent pool:                          $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version

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

if [ "$SID" != "$SID_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The sid setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$SID' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$SID_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
	exit 2
fi

workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"
echo "Workload Zone Environment File:      $workload_environment_file_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none --only-show-errors

az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project='$SYSTEM_TEAMPROJECT' --output none

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

echo -e "$green--- Read parameter values ---$reset"

dos2unix -q "${workload_environment_file_name}"

prefix="${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
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
	workload_key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultName" "${WORKLOAD_ZONE_NAME}")
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


echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $key_vault"
echo "Workload Key vault:                  ${workload_key_vault}"
echo "Target subscription                  $WL_ARM_SUBSCRIPTION_ID"

echo "Terraform state file subscription:   $STATE_SUBSCRIPTION"
echo "Terraform state file storage account:$REMOTE_STATE_SA"

tfstate_resource_id=$(az resource list --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
export tfstate_resource_id

echo -e "$green--- Deploy the System ---$reset"
cd "$CONFIG_REPO_PATH/SYSTEM/$WORKLOAD_ZONE_FOLDERNAME" || exit
source "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh"
install --parameterfile $WORKLOAD_ZONE_TFVARS_FILENAME --type sap_system \
	--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_id "${APPLICATION_CONFIGURATION_ID}" \
	--workload_zone_name "${WORKLOAD_ZONE_NAME}" \
	--ado --auto-approve

return_code=$?
echo "Return code from deployment:         ${return_code}"
if [ 0 != $return_code ]; then
	echo "##vso[task.logissue type=error]Return code from installer $return_code."
fi

set +o errexit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"
cd "$CONFIG_REPO_PATH" || exit
echo -e "$green--- Pull the latest content from DevOps ---$reset"
# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

# Pull changes if there are other deployment jobs

cd "${CONFIG_REPO_PATH}/SYSTEM/$WORKLOAD_ZONE_FOLDERNAME" || exit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"

if [ -f stdout.az ]; then
	rm stdout.az
fi

added=0

if [ -f .terraform/terraform.tfstate ]; then
	git add -f .terraform/terraform.tfstate
	added=1
fi

if [ -f sap-parameters.yaml ]; then
	git add sap-parameters.yaml
	added=1
else
	return_code=1
fi

if [ -f "${SID}_hosts.yaml" ]; then
	git add -f "${SID}_hosts.yaml"
	added=1
fi

if [ -f "${SID}.md" ]; then
	git add "${CONFIG_REPO_PATH}/SYSTEM/$WORKLOAD_ZONE_FOLDERNAME/${SID}.md"
	# echo "##vso[task.uploadsummary]./${SID}.md)"
	added=1
fi

if [ -f "${SID}_inventory.md" ]; then
	git add "${SID}_inventory.md"
	added=1
fi

if [ -f "${SID}_resource_names.json" ]; then
	git add "${SID}_resource_names.json"
	added=1
fi

if [ -f $WORKLOAD_ZONE_TFVARS_FILENAME ]; then
	git add $WORKLOAD_ZONE_TFVARS_FILENAME
	added=1
fi

if [ -f "${SID}_virtual_machines.json" ]; then
	git add "${SID}_virtual_machines.json"
	added=1
fi

if [ 1 == $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from SAP deployment of $WORKLOAD_ZONE_FOLDERNAME for $BUILD_BUILDNUMBER [skip ci]"

	if git -c http.extraheader="AUTHORIZATION: bearer SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Changes from SAP deployment of $WORKLOAD_ZONE_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi
fi

# file_name=${SID}_inventory.md
# if [ -f ${SID}_inventory.md ]; then
#   az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project='$SYSTEM_TEAMPROJECT' --output none

#   # ToDo: Fix this later
#   # WIKI_NAME_FOUND=$(az devops wiki list --query "[?name=='SDAF'].name | [0]")
#   # echo "${WIKI_NAME_FOUND}"
#   # if [ -n "${WIKI_NAME_FOUND}" ]; then
#   #   eTag=$(az devops wiki page show --path "${file_name}" --wiki SDAF --query eTag )
#   #   if [ -n "$eTag" ]; then
#   #     az devops wiki page update --path "${file_name}" --wiki SDAF --file-path ./"${file_name}" --only-show-errors --version $eTag --output none
#   #   else
#   #     az devops wiki page create --path "${file_name}" --wiki SDAF --file-path ./"${file_name}" --output none --only-show-errors
#   #   fi
#   # fi
# fi

exit $return_code

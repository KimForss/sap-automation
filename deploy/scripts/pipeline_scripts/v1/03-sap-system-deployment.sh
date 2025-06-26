#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
<<<<<<< HEAD


#External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="Deploy SAP System"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

echo "##vso[build.updatebuildnumber]Deploying the SAP System defined in $SAP_SYSTEM_FOLDERNAME"
=======
cyan="\e[1;36m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"
>>>>>>> 591634d45 (Bring in the new scripts)

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
<<<<<<< HEAD
=======
	set -o errexit
>>>>>>> 591634d45 (Bring in the new scripts)
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

<<<<<<< HEAD
# Print the execution environment details
print_header

# Configure DevOps
configure_devops

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID" ;
then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

tfvarsFile="SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME"

=======
echo "##vso[build.updatebuildnumber]Deploying the SAP System defined in $SAP_SYSTEM_FOLDERNAME"

tfvarsFile="SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME"

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

>>>>>>> 591634d45 (Bring in the new scripts)
cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

<<<<<<< HEAD
if [ ! -f "$CONFIG_REPO_PATH/$tfvarsFile" ]; then
	print_banner "$banner_title" "$SAP_SYSTEM_TFVARS_FILENAME was not found" "error"
=======
if [ ! -f "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME/$SAP_SYSTEM_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $SAP_SYSTEM_TFVARS_FILENAME was not found ---$reset"
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]File $SAP_SYSTEM_TFVARS_FILENAME was not found."
	exit 2
fi

<<<<<<< HEAD
# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$(tf_version)"
	echo -e "$green--- az login ---$reset"
	if ! LogonToAzure false; then
		print_banner "$banner_title" "Login to Azure failed" "error"
		echo "##vso[task.logissue type=error]az login failed."
		exit 2
	fi
else
	if [ "$USE_MSI" == "true" ]; then
		TF_VAR_use_spn=false
		export TF_VAR_use_spn
		ARM_USE_MSI=true
		export ARM_USE_MSI
		echo "Deployment using:                    Managed Identity"
	else
		TF_VAR_use_spn=true
		export TF_VAR_use_spn
		ARM_USE_MSI=false
		export ARM_USE_MSI
		echo "Deployment using:                    Service Principal"
	fi
	ARM_CLIENT_ID=$(grep -m 1 "export ARM_CLIENT_ID=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export ARM_CLIENT_ID
fi

if printenv OBJECT_ID; then
	if is_valid_guid "$OBJECT_ID"; then
		TF_VAR_spn_id="$OBJECT_ID"
		export TF_VAR_spn_id
	fi
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

=======
echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

	if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$ARM_SUBSCRIPTION_ID" == '$$(ARM_SUBSCRIPTION_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$ARM_CLIENT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$ARM_CLIENT_ID" == '$$(ARM_CLIENT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$ARM_CLIENT_SECRET" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$ARM_CLIENT_SECRET" == '$$(ARM_CLIENT_SECRET)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ -z "$ARM_TENANT_ID" ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi

	if [ "$ARM_TENANT_ID" == '$$(ARM_TENANT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $VARIABLE_GROUP variable group."
		exit 2
	fi
fi

# Set logon variables
if [ $USE_MSI == "true" ]; then
	unset ARM_CLIENT_SECRET
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi
if az account show --query name; then
	echo -e "$green--- Already logged in to Azure ---$reset"
else
	# Check if running on deployer
	if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
		configureNonDeployer "${tf_version:-1.12.2}"
		echo -e "$green--- az login ---$reset"
		LogonToAzure $USE_MSI
	else
		LogonToAzure $USE_MSI
	fi
	return_code=$?
	if [ 0 != $return_code ]; then
		echo -e "$bold_red--- Login failed ---$reset"
		echo "##vso[task.logissue type=error]az login failed."
		exit $return_code
	fi
fi
az account set --subscription "$ARM_SUBSCRIPTION_ID"

echo -e "$green--- Read deployment details ---$reset"
dos2unix -q tfvarsFile

>>>>>>> 591634d45 (Bring in the new scripts)
ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
SID=$(grep -m1 "^sid" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $1}')
<<<<<<< HEAD
LOCATION_CODE_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $3}')
SID_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $4}')

WORKLOAD_ZONE_NAME=$(echo "$SAP_SYSTEM_FOLDERNAME" | cut -d'-' -f1-3)
landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"
control_plane_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$CONTROL_PLANE_NAME"

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
export deployer_tfstate_key

echo ""
echo -e "${green}Deployment details:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "CONTROL_PLANE_NAME:                  $CONTROL_PLANE_NAME"
echo "WORKLOAD_ZONE_NAME:                  $WORKLOAD_ZONE_NAME"
echo "Workload Zone Environment File:      $workload_environment_file_name"
echo "Control Plane Environment File:      $control_plane_environment_file_name"

echo "Environment:                         $ENVIRONMENT"
echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location:                            $LOCATION"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network:                             $NETWORK"
echo "Network(filename):                   $NETWORK_IN_FILENAME"
echo "SID:                                 $SID"
echo "SID(filename):                       $SID_IN_FILENAME"
=======

LOCATION_CODE_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

NETWORK_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $3}')

SID_IN_FILENAME=$(echo $SAP_SYSTEM_FOLDERNAME | awk -F'-' '{print $4}')

echo "System TFvars:                       $SAP_SYSTEM_TFVARS_FILENAME"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Network:                             $NETWORK"
echo "SID:                                 $SID"

echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network(filename):                   $NETWORK_IN_FILENAME"
echo "SID(filename):                       $SID_IN_FILENAME"

echo ""

echo "Agent pool:                          $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version
>>>>>>> 591634d45 (Bring in the new scripts)

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The environment setting in $SAP_SYSTEM_TFVARS_FILENAME '$ENVIRONMENT' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $SAP_SYSTEM_TFVARS_FILENAME '$LOCATION' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The network_logical_name setting in $SAP_SYSTEM_TFVARS_FILENAME '$NETWORK' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$SID" != "$SID_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The sid setting in $SAP_SYSTEM_TFVARS_FILENAME '$SID' does not match the $SAP_SYSTEM_TFVARS_FILENAME file name '$SID_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
	exit 2
fi

<<<<<<< HEAD
if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
  application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)
	DEPLOYER_KEYVAULT=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "${CONTROL_PLANE_NAME}")
	if [ -z "$key_vault_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	workload_key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${WORKLOAD_ZONE_NAME}_KeyVaultName" "${WORKLOAD_ZONE_NAME}")

	management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
	TF_VAR_management_subscription_id=${management_subscription_id}
	export TF_VAR_management_subscription_id
else
  print_banner "$banner_title" "APPLICATION_CONFIGURATION_ID was not found" "info"
	echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	load_config_vars "${control_plane_environment_file_name}" "DEPLOYER_KEYVAULT" "tfstate_resource_id"
	key_vault_id=$(az resource list --name "${DEPLOYER_KEYVAULT}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
fi

if [ -z "$DEPLOYER_KEYVAULT" ]; then
	echo "##vso[task.logissue type=error]Key vault name (${CONTROL_PLANE_NAME}_KeyVaultName) was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	exit 2
fi

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${workload_environment_file_name})."
	exit 2
fi

export TF_VAR_spn_keyvault_id=${key_vault_id}

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
TF_VAR_tfstate_resource_id=${tfstate_resource_id}
export TF_VAR_tfstate_resource_id

export workload_key_vault

echo ""
echo -e "${green}Terraform parameter information:"
echo -e "-------------------------------------------------------------------------------$reset"

echo "System TFvars:                       $SAP_SYSTEM_TFVARS_FILENAME"
echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $DEPLOYER_KEYVAULT"
echo "Statefile subscription:              $terraform_storage_account_subscription_id"
echo "Statefile storage account:           $terraform_storage_account_name"
echo ""
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit
if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file "$SAP_SYSTEM_TFVARS_FILENAME" --type sap_system \
	--control_plane_name "${CONTROL_PLANE_NAME}" --storage_accountname "$terraform_storage_account_name"  \
	--workload_zone_name "${WORKLOAD_ZONE_NAME}" \
	--ado --auto-approve ; then
	return_code=$?
	print_banner "$banner_title" "Deployment of $SAP_SYSTEM_FOLDERNAME completed successfully" "success"
else
	return_code=$?
	print_banner "$banner_title" "Deployment of $SAP_SYSTEM_FOLDERNAME failed" "error"
	echo -e "$bold_red--- Deployment failed ---$reset"
	echo "##vso[task.logissue type=error]Deployment failed."
fi
=======
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
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

deployer_tfstate_key=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key" || true)
export deployer_tfstate_key

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${workload_environment_file_name}" "keyvault" || true)
export key_vault

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${workload_environment_file_name}" "REMOTE_STATE_SA" || true)
export REMOTE_STATE_SA

STATE_SUBSCRIPTION=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${workload_environment_file_name}" "STATE_SUBSCRIPTION" || true)
export STATE_SUBSCRIPTION

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Key_Vault" "${workload_environment_file_name}" "workloadkeyvault" || true)
export workload_key_vault

landscape_tfstate_key=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Zone_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key" || true)
export landscape_tfstate_key

echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $key_vault"
echo "Workload Key vault:                  ${workload_key_vault}"
echo "Target subscription                  $ARM_SUBSCRIPTION_ID"

echo "Terraform state file subscription:   $STATE_SUBSCRIPTION"
echo "Terraform state file storage account:$REMOTE_STATE_SA"

tfstate_resource_id=$(az resource list --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
export tfstate_resource_id

echo -e "$green--- Deploy the System ---$reset"
cd "$CONFIG_REPO_PATH/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer.sh" --parameterfile $SAP_SYSTEM_TFVARS_FILENAME --type sap_system \
	--state_subscription "${STATE_SUBSCRIPTION}" --storageaccountname "${REMOTE_STATE_SA}" \
	--deployer_tfstate_key "${deployer_tfstate_key}" --landscape_tfstate_key "${landscape_tfstate_key}" \
	--ado --auto-approve

return_code=$?
>>>>>>> 591634d45 (Bring in the new scripts)
echo "Return code from deployment:         ${return_code}"
if [ 0 != $return_code ]; then
	echo "##vso[task.logissue type=error]Return code from installer $return_code."
fi

set +o errexit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"
cd "$CONFIG_REPO_PATH" || exit
<<<<<<< HEAD
=======
echo -e "$green--- Pull the latest content from DevOps ---$reset"
>>>>>>> 591634d45 (Bring in the new scripts)
# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

# Pull changes if there are other deployment jobs

cd "${CONFIG_REPO_PATH}/SYSTEM/$SAP_SYSTEM_FOLDERNAME" || exit

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
	git add "${CONFIG_REPO_PATH}/SYSTEM/$SAP_SYSTEM_FOLDERNAME/${SID}.md"
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

<<<<<<< HEAD
if [ -f "$SAP_SYSTEM_TFVARS_FILENAME" ]; then
	git add "$SAP_SYSTEM_TFVARS_FILENAME"
=======
if [ -f $SAP_SYSTEM_TFVARS_FILENAME ]; then
	git add $SAP_SYSTEM_TFVARS_FILENAME
>>>>>>> 591634d45 (Bring in the new scripts)
	added=1
fi

if [ -f "${SID}_virtual_machines.json" ]; then
	git add "${SID}_virtual_machines.json"
	added=1
fi

if [ 1 == $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from SAP deployment of $SAP_SYSTEM_FOLDERNAME for $BUILD_BUILDNUMBER [skip ci]"

	if git -c http.extraheader="AUTHORIZATION: bearer SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Changes from SAP deployment of $SAP_SYSTEM_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi
fi

# file_name=${SID}_inventory.md
# if [ -f ${SID}_inventory.md ]; then
<<<<<<< HEAD
#   az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project=$SYSTEM_TEAMPROJECTID --output none
=======
#   az devops configure --defaults organization=$SYSTEM_COLLECTIONURI project='$SYSTEM_TEAMPROJECT' --output none
>>>>>>> 591634d45 (Bring in the new scripts)

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

<<<<<<< HEAD
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

=======
>>>>>>> 591634d45 (Bring in the new scripts)
exit $return_code

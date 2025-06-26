#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

<<<<<<< HEAD
green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"

#External helper functions
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="Remove SAP System"

#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

echo "##vso[build.updatebuildnumber]Removing workload zone defined in  defined in $WORKLOAD_ZONE_FOLDERNAME"
=======
echo "##vso[build.updatebuildnumber]Removing the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"

green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"
>>>>>>> 591634d45 (Bring in the new scripts)

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
<<<<<<< HEAD
	echo "Environment variables:"
	printenv | sort

=======
>>>>>>> 591634d45 (Bring in the new scripts)
fi
export DEBUG
set -eu

<<<<<<< HEAD
# Print the execution environment details
print_header

# Configure DevOps
configure_devops

if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
fi
export VARIABLE_GROUP_ID

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/$tfvarsFile" ]; then
	print_banner "$banner_title" "$WORKLOAD_ZONE_TFVARS_FILENAME was not found" "error"
=======
tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git checkout -q "$BUILD_SOURCEBRANCHNAME"

if [ ! -f "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $WORKLOAD_ZONE_TFVARS_FILENAME was not found ---$reset"
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]File $WORKLOAD_ZONE_TFVARS_FILENAME was not found."
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

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')
<<<<<<< HEAD
LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

WORKLOAD_ZONE_NAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | cut -d'-' -f1-3)
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
=======

LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

echo "Workload TFvars:                     $WORKLOAD_ZONE_TFVARS_FILENAME"
echo "Environment:                         $ENVIRONMENT"
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
>>>>>>> 591634d45 (Bring in the new scripts)

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

echo "System TFvars:                       $WORKLOAD_ZONE_TFVARS_FILENAME"
echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload statefile:                  $landscape_tfstate_key"
echo "Deployer Key vault:                  $DEPLOYER_KEYVAULT"
echo "Statefile subscription:              $terraform_storage_account_subscription_id"
echo "Statefile storage account:           $terraform_storage_account_name"
echo ""
echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remover_v2.sh" --parameter_file "$WORKLOAD_ZONE_TFVARS_FILENAME" --type sap_landscape \
	--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "${APPLICATION_CONFIGURATION_NAME}" \
	--workload_zone_name "${WORKLOAD_ZONE_NAME}" \
	--ado --auto-approve; then
	return_code=$?
	print_banner "$banner_title" "The removal of $WORKLOAD_ZONE_TFVARS_FILENAME succeeded" "success" "Return code: ${return_code}"
else
	return_code=$?
	print_banner "$banner_title" "The removal of $WORKLOAD_ZONE_TFVARS_FILENAME failed" "error" "Return code: ${return_code}"
fi

echo
if [ 0 != $return_code ]; then
	echo "##vso[task.logissue type=error]Return code from remover $return_code."
else
	if [ 0 == $return_code ]; then
		# Pull changes
		git checkout -q "$BUILD_SOURCEBRANCHNAME"
		git pull origin "$BUILD_SOURCEBRANCHNAME"

		git clean -d -f -X

		if [ -f ".terraform/terraform.tfstate" ]; then
			git rm --ignore-unmatch -q --ignore-unmatch ".terraform/terraform.tfstate"
			changed=1
		fi

		if [ -d ".terraform" ]; then
			git rm -q -r --ignore-unmatch ".terraform"
			changed=1
		fi

		if [ -d .terraform ]; then
			rm -r .terraform
		fi

		if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
			git add "$WORKLOAD_ZONE_TFVARS_FILENAME"
			changed=1
		fi

		if [ 1 == $changed ]; then
			git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
			git config --global user.name "$BUILD_REQUESTEDFOR"

			if git commit -m "Infrastructure for $WORKLOAD_ZONE_TFVARS_FILENAME removed. [skip ci]"; then
				if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
					echo "##vso[task.logissue type=warning]Removal of $WORKLOAD_ZONE_TFVARS_FILENAME updated in $BUILD_BUILDNUMBER"
				else
					echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
				fi
			fi
		fi
	fi
	echo -e "$green--- Deleting variables ---$reset"
	if [ -n "$VARIABLE_GROUP_ID" ]; then
		print_banner "Remove workload zone" "Deleting variables" "info"

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "CONTROL_PLANE_NAME.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name CONTROL_PLANE_NAME --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_ID.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name APPLICATION_CONFIGURATION_ID --yes --only-show-errors
		fi
	fi
fi
=======
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
echo "Workload Zone Environment File:      $workload_environment_file_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none --only-show-errors

az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project='$SYSTEM_TEAMPROJECT'

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
export VARIABLE_GROUP_ID
if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi

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

echo -e "$green--- Run the remover script that destroys the SAP system ---$reset"

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/remover.sh \
	--parameterfile $WORKLOAD_ZONE_TFVARS_FILENAME \
	--type sap_landscape \
	--state_subscription "${STATE_SUBSCRIPTION}" \
	--storageaccountname "${REMOTE_STATE_SA}" \
	--deployer_tfstate_key "${deployer_tfstate_key}" \
	--auto-approve

return_code=$?
echo -e "$green--- Pull latest from DevOps Repository ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git pull

#stop the pipeline after you have reset the whitelisting on your resources
echo "Return code from remover.sh:         $return_code."
if [ 0 != $return_code ]; then
	echo "##vso[task.logissue type=error]Return code from remover.sh $return_code."
	exit $return_code
fi

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"

cd "$CONFIG_REPO_PATH" || exit

changed=0
# Pull changes
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git pull origin "$BUILD_SOURCEBRANCHNAME"
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git pull origin "$BUILD_SOURCEBRANCHNAME"

cd "${CONFIG_REPO_PATH}" || exit

if [ 0 == $return_code ]; then

	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}" ]; then
		git rm --ignore-unmatch -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}.md" ]; then
		git rm --ignore-unmatch -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}${NETWORK}.md"
		changed=1
	fi

	cd "${CONFIG_REPO_PATH}/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

	if [ -d ".terraform" ]; then
		git rm -q -r --ignore-unmatch -f ".terraform"
		changed=1
		rm -rf .terraform
	fi

	if [ -f "${ENVIRONMENT}${LOCATION}${NETWORK}.md" ]; then
		git rm --ignore-unmatch -f "${ENVIRONMENT}${LOCATION}${NETWORK}.md"
		changed=1
	fi

	if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
		git add "$WORKLOAD_ZONE_TFVARS_FILENAME"
		changed=1
	fi

	if [ 1 == $changed ]; then
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"

		if git commit -m "Infrastructure for $WORKLOAD_ZONE_TFVARS_FILENAME removed. [skip ci]"; then
			if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
				echo "##vso[task.logissue type=warning]Removal of $WORKLOAD_ZONE_TFVARS_FILENAME updated in $BUILD_SOURCEBRANCHNAME"
			else
				echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
			fi
		fi
	fi
fi

>>>>>>> 591634d45 (Bring in the new scripts)
exit $return_code

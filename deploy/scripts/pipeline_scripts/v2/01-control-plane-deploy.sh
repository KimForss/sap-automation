#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
green="\e[1;32m"
reset="\e[0m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
banner_title="Deploy Control Plane"
#call stack has full script name when using source
# shellcheck disable=SC1091
source "${grand_parent_directory}/deploy_utils.sh"

#call stack has full script name when using source
source "${parent_directory}/helper.sh"

DEBUG=False

if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi
export DEBUG
set -eu

print_banner "$banner_title" "Starting $SCRIPT_NAME" "info"

echo -e "$green--- File Validations ---$reset"

if [ ! -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" ]; then

	print_banner "$banner_title" "File ${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found" "error"
	echo "##vso[task.logissue type=error]File ${CONFIG_REPO_PATH}/${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi

if [ ! -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" ]; then
	print_banner "$banner_title" "File ${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found" "error"
	echo "##vso[task.logissue type=error]File ${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

if [ -z $CONTROL_PLANE_NAME ]; then
	CONTROL_PLANE_NAME=$(echo "$DEPLOYER_FOLDERNAME" | cut -d'-' -f1-3)
	export $CONTROL_PLANE_NAME
fi

application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)

deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/${CONTROL_PLANE_NAME}"
deployer_configuration_file="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
library_configuration_file="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
if [ -f "${deployer_environment_file_name}" ]; then
	step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
	echo "Step:                                $step"
fi

terraform_storage_account_name=""
terraform_storage_account_resource_group_name=$DEPLOYER_FOLDERNAME

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path

	ARM_CLIENT_ID=$(grep -m 1 "export ARM_CLIENT_ID=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	ARM_USE_MSI=true
	export ARM_USE_MSI
fi

echo -e "$green--- Information ---$reset"
echo "Agent:                               $THIS_AGENT"
echo "Control Plane Name:                  $CONTROL_PLANE_NAME"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
if [ -n "$TF_VAR_agent_pat" ]; then
	echo "Deployer Agent PAT:                  IsDefined"
fi
if [ -n "$POOL" ]; then
	echo "Deployer Agent Pool:                 $POOL"
fi
echo ""
echo "Deployer Folder:                     $DEPLOYER_FOLDERNAME"
echo "Deployer TFvars:                     $DEPLOYER_TFVARS_FILENAME"
echo "Library Folder:                      $LIBRARY_FOLDERNAME"
echo "Library TFvars:                      $LIBRARY_TFVARS_FILENAME"

echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version
echo ""
echo "Terraform version:"
echo "-------------------------------------------------"
if [ -f /opt/terraform/bin/terraform ]; then
	tfPath="/opt/terraform/bin/terraform"
else
	tfPath=$(which terraform)
fi

"${tfPath}" --version

cd "$CONFIG_REPO_PATH" || exit

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
if ! az extension list --query "[?contains(name, 'azure-devops')]" --output table; then
	az extension add --name azure-devops --output none --only-show-errors
fi

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

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$(tf_version)"
	echo -e "$green--- az login ---$reset"
	if ! LogonToAzure false; then
		print_banner "$banner_title" "Login to Azure failed" "error"
		echo "##vso[task.logissue type=error]az login failed."
		exit 2
	fi
fi
return_code=$?

TF_VAR_subscription_id=$ARM_SUBSCRIPTION_ID
export TF_VAR_subscription_id

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

echo -e "$green--- Configuring variables ---$reset"

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	key_vault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
	key_vault_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "${CONTROL_PLANE_NAME}")
	if [ -z "$key_vault_id" ]; then
		echo "##vso[task.logissue type=error]Key '${CONTROL_PLANE_NAME}_KeyVaultResourceId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
else
	echo "##vso[task.logissue type=error]Variable APPLICATION_CONFIGURATION_ID was not defined."
	load_config_vars "${deployer_environment_file_name}" "keyvault"
	key_vault="$keyvault"
	load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id"
	key_vault_id=$(az resource list --name "${keyvault}" --subscription "$ARM_SUBSCRIPTION_ID" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
fi

TF_VAR_spn_keyvault_id=${key_vault_id}
export TF_VAR_spn_keyvault_id

if [ -n "${key_vault}" ]; then
	echo "Deployer Key Vault:                  ${key_vault}"
	keyvault_parameter=" --keyvault ${key_vault} "
else
	echo "Deployer Key Vault:                  undefined"
	exit 2

fi

terraform_storage_account_subscription_id=$ARM_SUBSCRIPTION_ID

echo "Terraform state subscription:        $terraform_storage_account_subscription_id"

if [ -n "$tfstate_resource_id" ]; then
	terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
	terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
	terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)
	echo "Terraform storage account:           $terraform_storage_account_name"
	storage_account_parameter=" --storageaccountname ${terraform_storage_account_name} "

	export terraform_storage_account_name
	export terraform_storage_account_resource_group_name
	export terraform_storage_account_subscription_id
	export tfstate_resource_id

else
	echo "Terraform storage account:            undefined"
	storage_account_parameter=
fi

echo -e "$green--- Validations ---$reset"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
	export TF_VAR_ansible_core_version=2.16
fi

echo -e "$green--- Update .sap_deployment_automation/config as SAP_AUTOMATION_REPO_PATH can change on devops agent ---$reset"
cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
echo "SAP_AUTOMATION_REPO_PATH=$SAP_AUTOMATION_REPO_PATH" >.sap_deployment_automation/config
export SAP_AUTOMATION_REPO_PATH

if [ -n "${key_vault}" ]; then

	key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
	if [ -n "${key_vault_id}" ]; then
		if [ "azure pipelines" = "$THIS_AGENT" ]; then
			this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
			az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --only-show-errors --output none
		fi
	fi
fi

echo -e "$green--- Preparing for the Control Plane deployment---$reset"

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
	# shellcheck disable=SC2001
	pass=${SYSTEM_COLLECTIONID//-/}

	echo "Unzipping the library state file"
	unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME"
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}

	echo "Unzipping the deployer state file"
	unzip -o -qq -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

export TF_LOG_PATH=${CONFIG_REPO_PATH}/.sap_deployment_automation/terraform.log

print_banner "$banner_title" "Calling deploy_control_plane_v2" "info"

msi_flag=""
if [ "$USE_MSI" != "true" ]; then
	msi_flag=" --msi "
	export TF_VAR_use_spn=false
else
	export TF_VAR_use_spn=true
fi

if "${SAP_AUTOMATION_REPO_PATH}/deploy/scripts/deploy_control_plane_v2.sh" --deployer_parameter_file "${deployer_configuration_file}" \
	--library_parameter_file "${library_configuration_file}" \
	--subscription "$ARM_SUBSCRIPTION_ID" \
	--auto-approve --ado "$msi_flag" \
	"${storage_account_parameter}" "${keyvault_parameter}"; then
	return_code=$?
	echo "##vso[task.logissue type=warning]Return code from deploy_control_plane_v2 $return_code."
	echo "Return code from deploy_control_plane_v2 $return_code."
else
	return_code=$?
	echo "##vso[task.logissue type=error]Return code from deploy_control_plane_v2 $return_code."
	echo "Return code from deploy_control_plane_v2 $return_code."

fi

echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "${CONFIG_REPO_PATH}" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Update repo ---$reset"
if [ -f ".sap_deployment_automation/$CONTROL_PLANE_NAME" ]; then
	git add ".sap_deployment_automation/$CONTROL_PLANE_NAME"
	added=1
fi

if [ -f .".sap_deployment_automation/${CONTROL_PLANE_NAME}.md" ]; then
	git add .".sap_deployment_automation/${CONTROL_PLANE_NAME}.md"
	added=1
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" ]; then
	git add -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	added=1

	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	local_backend=$(grep "\"type\": \"local\"" DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate || true)

	if [ -n "$local_backend" ]; then
		echo "Deployer Terraform state:              local"

		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
			echo "Compressing the deployer state file"
			sudo apt-get -qq install zip

			pass=${SYSTEM_COLLECTIONID//-/}
			zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
			git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
			rm "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
			added=1
		fi
	else
		echo "Deployer Terraform state:              remote"
		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
			git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
			echo "Removed the deployer state file"
			added=1
		fi
		if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
			if [ 0 == $return_code ]; then
				echo "Removing the deployer state zip file"
				git rm -q --ignore-unmatch -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"

				added=1
			fi
		fi
	fi
fi

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" ]; then
	git add -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
	added=1
fi

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" ]; then
	git add -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
	added=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	local_backend=$(grep "\"type\": \"local\"" LIBRARY/$LIBRARY_FOLDERNAME/.terraform/terraform.tfstate || true)
	if [ -n "$local_backend" ]; then
		echo "Library Terraform state:               local"
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
			sudo apt-get -qq install zip

			echo "Compressing the library state file"
			pass=${SYSTEM_COLLECTIONID//-/}
			zip -q -j -P "${pass}" "LIBRARY/$LIBRARY_FOLDERNAME/state" "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
			git add -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
			rm "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
			added=1
		fi
	else
		echo "Library Terraform state:               remote"
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
			if [ 0 == $return_code ]; then
				echo "Removing the library state file"
				git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
				added=1
			fi
		fi
		if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
			echo "Removing the library state zip file"
			git rm -q --ignore-unmatch -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
			added=1
		fi
	fi
fi

if [ 1 = $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	if [ $DEBUG = True ]; then
		git status --verbose
		if git commit --message --verbose "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"; then
			if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
				echo "Failed to push changes to the repository."
			fi
		fi

	else
		if git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"; then
			if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
				echo "Failed to push changes to the repository."
			fi
		fi
	fi
fi

echo -e "$green--- Adding variables to the variable group: $VARIABLE_GROUP ---$reset"
if [ 0 = $return_code ]; then

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"; then
		echo "Variable CONTROL_PLANE_NAME was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
		echo "Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
	fi

fi
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code

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

#call stack has full script name when using source
source "${parent_directory}/helper.sh"
source "${grand_parent_directory}/deploy_utils.sh"
SCRIPT_NAME="$(basename "$0")"

banner_title="Remove Control Plane"
=======
echo "##vso[build.updatebuildnumber]Removing the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
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
<<<<<<< HEAD
	set -o errexit
	DEBUG=True
	echo "Environment variables:"
	printenv | sort

fi


export DEBUG
set -eu
=======
	set -eu
	DEBUG=True
fi

export DEBUG
>>>>>>> 591634d45 (Bring in the new scripts)
# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

<<<<<<< HEAD
echo "##vso[build.updatebuildnumber]Removing the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"

print_banner "$banner_title" "Entering $SCRIPT_NAME" "info"

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
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
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
# Print the execution environment details
print_header

# Configure DevOps
configure_devops

CONTROL_PLANE_NAME=$(echo "$DEPLOYER_FOLDERNAME" | cut -d'-' -f1-3)
export "CONTROL_PLANE_NAME"

VARIABLE_GROUP="SDAF-${CONTROL_PLANE_NAME}"
deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"
deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/$CONTROL_PLANE_NAME"


if ! get_variable_group_id "$VARIABLE_GROUP" "VARIABLE_GROUP_ID" ;
then
	echo -e "$bold_red--- Variable group $VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP not found."
	exit 2
else
  DEPLOYER_KEYVAULT=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT")

	TF_VAR_spn_keyvault_id=$(az keyvault show --name "$DEPLOYER_KEYVAULT" --subscription "$ARM_SUBSCRIPTION_ID" --query id -o tsv)
	export TF_VAR_spn_keyvault_id
fi
export VARIABLE_GROUP_ID

TF_VAR_deployer_tfstate_key="$deployer_tfstate_key"
export TF_VAR_deployer_tfstate_key

if [ ! -f "$deployerTFvarsFile" ]; then
	print_banner "$banner_title" "$deployerTFvarsFile was not found" "error"
=======
cd "$CONFIG_REPO_PATH" || exit

deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"
deployer_tfstate_key="$DEPLOYER_FOLDERNAME.terraform.tfstate"

echo ""
echo -e "$cyan Starting the removal of the deployer and its associated infrastructure $reset"
echo ""

echo -e "$green--- File Validations ---$reset"

if [ ! -f "$deployerTFvarsFile" ]; then
	echo -e "$bold_red--- File ${deployerTFvarsFile} was not found ---$reset"
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi

if [ ! -f "${libraryTFvarsFile}" ]; then
<<<<<<< HEAD
	print_banner "$banner_title" "$libraryTFvarsFile was not found" "error"
=======
	echo -e "$bold_red--- File ${libraryTFvarsFile}  was not found ---$reset"
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

<<<<<<< HEAD
=======
TF_VAR_deployer_tfstate_key="$deployer_tfstate_key"
export TF_VAR_deployer_tfstate_key

echo -e "$green--- Environment information ---$reset"
ENVIRONMENT=$(grep -m1 "^environment" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"' || true)
LOCATION=$(grep -m1 "^location" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"' || true)
deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/${ENVIRONMENT}$LOCATION"

# shellcheck disable=SC2005
ENVIRONMENT_IN_FILENAME=$(echo $DEPLOYER_FOLDERNAME | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo $DEPLOYER_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

echo "Environment:                         ${ENVIRONMENT}"
echo "Location:                            ${LOCATION}"
echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo ""
echo "Agent:                               $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
if [ -n "$POOL" ]; then
	echo "Deployer Agent Pool:                 $POOL"
fi

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The environment setting in $deployerTFvarsFile $ENVIRONMENT does not match the $DEPLOYER_FOLDERNAME file name $ENVIRONMENT_IN_FILENAME. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
	echo "##vso[task.logissue type=error]The location setting in $deployerTFvarsFile $LOCATION does not match the $DEPLOYER_FOLDERNAME file name $LOCATION_IN_FILENAME. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$ENVIRONMENT$LOCATION_CODE_IN_FILENAME"
echo "Environment file:                    $deployer_environment_file_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add --name azure-devops --output none --only-show-errors
az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none --only-show-errors

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
fi

echo -e "$green--- Information ---$reset"
VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$PARENT_VARIABLE_GROUP'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP could not be found."
	exit 2
fi

>>>>>>> 591634d45 (Bring in the new scripts)
if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
	echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
	exit 2
fi

<<<<<<< HEAD
az account set --subscription "$ARM_SUBSCRIPTION_ID"

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME"
	sudo rm -f "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
	sudo rm -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
fi

echo -e "$green--- Running the remove remove_control_plane_v2 that destroys SAP library ---$reset"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_control_plane_v2.sh" \
	--deployer_parameter_file "$deployerTFvarsFile" \
	--library_parameter_file "$libraryTFvarsFile" \
	--ado --auto-approve --keep_agent; then
	return_code=$?
  print_banner "$banner_title" "Control Plane $DEPLOYER_FOLDERNAME removal step 1 completed" "success"

	echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 1 completed."
else
	return_code=$?
  print_banner "$banner_title" "Control Plane $DEPLOYER_FOLDERNAME removal step 1 failed" "error"
fi

echo "Return code from remove_control_plane_v2: $return_code."

echo -e "$green--- Remove Control Plane Part 1 ---$reset"
cd "$CONFIG_REPO_PATH" || exit
git checkout -q "$BUILD_SOURCEBRANCHNAME"

changed=0
if [ -f "$deployer_environment_file_name" ]; then
	git add "$deployer_environment_file_name"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile" ]; then
	sed -i /"custom_random_id"/d "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
	git add -f "LIBRARY/$LIBRARY_FOLDERNAME/$libraryTFvarsFile"
	changed=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	changed=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
	echo "Compressing the state file."
	sudo apt-get -qq install zip
	pass=${SYSTEM_COLLECTIONID//-/}

	if zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"; then
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
		changed=1
	fi
fi

if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/.terraform" ]; then
	git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/.terraform"
	changed=1
fi

if [ -d "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate" ]; then
	git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/terraform.tfstate"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/state.zip" ]; then
	git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/state.zip"
	changed=1
fi

if [ -f "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars" ]; then
	git rm -q --ignore-unmatch "LIBRARY/$LIBRARY_FOLDERNAME/backend-config.tfvars"
	changed=1
fi

if [ 1 == $changed ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"

	if git commit -m "Control Plane $DEPLOYER_FOLDERNAME removal step 1[skip ci]"; then

		if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
			return_code=$?
			echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 2 updated in $BUILD_SOURCEBRANCHNAME"
		else
			return_code=$?
			echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
=======
echo -e "$green--- Validations ---$reset"

if [ "$USE_MSI" != "true" ]; then

	if [ -v ARM_CLIENT_ID ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ "$ARM_CLIENT_ID" == '$$(ARM_CLIENT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ -v ARM_CLIENT_SECRET ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ "$ARM_CLIENT_SECRET" == '$$(ARM_CLIENT_SECRET)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ -v ARM_TENANT_ID ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

	if [ "$ARM_TENANT_ID" == '$$(ARM_TENANT_ID)' ]; then
		echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
		exit 2
	fi

fi

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
	configureNonDeployer "$TF_VERSION"

	ARM_CLIENT_ID="$servicePrincipalId"
	export ARM_CLIENT_ID
	TF_VAR_spn_id=$ARM_CLIENT_ID
	export TF_VAR_spn_id

	ARM_OIDC_TOKEN="$idToken"
	if [ -n "$ARM_OIDC_TOKEN" ]; then
		export ARM_OIDC_TOKEN
		ARM_USE_OIDC=true
		export ARM_USE_OIDC
		unset ARM_CLIENT_SECRET
	else
		unset ARM_OIDC_TOKEN
		ARM_CLIENT_SECRET="$servicePrincipalKey"
		export ARM_CLIENT_SECRET
	fi

	ARM_TENANT_ID="$tenantId"
	export ARM_TENANT_ID

	ARM_USE_AZUREAD=true
	export ARM_USE_AZUREAD

else
	echo -e "$green--- az login ---$reset"
	LogonToAzure "$USE_MSI"
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault" || true)
export key_vault

echo "Deployer Key Vault:                  $key_vault"

key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
if [ -n "${key_vault_id}" ]; then
	if [ "azure pipelines" = "$THIS_AGENT" ]; then
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --only-show-errors --output none
	fi
fi

cd "$CONFIG_REPO_PATH" || exit
echo -e "$green--- Running the remove_deployer script that destroys deployer VM ---$reset"

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	pass=${SYSTEM_COLLECTIONID//-/}
	unzip -qq -o -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

echo -e "$green--- Running the remove region script that destroys deployer VM and SAP library ---$reset"

cd "$CONFIG_REPO_PATH/DEPLOYER/$DEPLOYER_FOLDERNAME" || exit

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_deployer.sh" --auto-approve \
	--parameterfile "$DEPLOYER_TFVARS_FILENAME"; then
	return_code=$?
	echo "Control Plane $DEPLOYER_FOLDERNAME removal step 2 completed."
	echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 2 completed."
else
	return_code=$?
	echo "Control Plane $DEPLOYER_FOLDERNAME removal step 2 failed."
fi

echo "Return code from remove_deployer: $return_code."

echo -e "$green--- Remove Control Plane Part 2 ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"
git pull -q

if [ 0 == $return_code ]; then
	cd "$CONFIG_REPO_PATH" || exit
	changed=0

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile" ]; then
		sed -i /"custom_random_id"/d "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/$deployerTFvarsFile"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
		git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
		changed=1
	fi

	if [ -d "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform" ]; then
		git rm -q -r --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform"
		changed=1
	fi

	if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
		git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
		changed=1
	fi

	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}" ]; then
		rm ".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}"
		git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}"
		changed=1
	fi
	if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}.md" ]; then
		rm ".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}.md"
		git rm -q --ignore-unmatch ".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}.md"
		changed=1
	fi

	if [ 1 == $changed ]; then
		git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
		git config --global user.name "$BUILD_REQUESTEDFOR"
		if git commit -m "Control Plane $DEPLOYER_FOLDERNAME removal step 2[skip ci]"; then
			if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
				return_code=$?
				echo "##vso[task.logissue type=warning]Control Plane $DEPLOYER_FOLDERNAME removal step 2 updated in $BUILD_SOURCEBRANCHNAME"
			else
				return_code=$?
				echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
			fi
		fi
	fi
	echo -e "$green--- Deleting variables ---$reset"
	if [ ${#VARIABLE_GROUP_ID} != 0 ]; then
		echo "Deleting variables"

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Terraform_Remote_Storage_Account_Name.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Account_Name --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Terraform_Remote_Storage_Resource_Group_Name.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Resource_Group_Name --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Terraform_Remote_Storage_Subscription.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Terraform_Remote_Storage_Subscription --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Deployer_State_FileName.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Deployer_State_FileName --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "DEPLOYER_KEYVAULT.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_KEYVAULT --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_URL_BASE.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_URL_BASE --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_IDENTITY.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_IDENTITY --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_ID.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_ID --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "WEBAPP_RESOURCE_GROUP.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name WEBAPP_RESOURCE_GROUP --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "INSTALLATION_MEDIA_ACCOUNT.value")
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name INSTALLATION_MEDIA_ACCOUNT --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "DEPLOYER_RANDOM_ID.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name DEPLOYER_RANDOM_ID --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "LIBRARY_RANDOM_ID.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name LIBRARY_RANDOM_ID --yes --only-show-errors
		fi


		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ControlPlaneEnvironment.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name ControlPlaneEnvironment --yes --only-show-errors
		fi

		variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "ControlPlaneLocation.value" --out tsv)
		if [ ${#variable_value} != 0 ]; then
			az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name ControlPlaneLocation --yes --only-show-errors
>>>>>>> 591634d45 (Bring in the new scripts)
		fi
	fi

fi
<<<<<<< HEAD
print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"
=======
>>>>>>> 591634d45 (Bring in the new scripts)

exit $return_code

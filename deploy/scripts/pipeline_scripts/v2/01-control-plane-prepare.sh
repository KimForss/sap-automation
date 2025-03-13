#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME"
green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

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

step=0

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation

ENVIRONMENT=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $1}' | xargs)
LOCATION=$(echo "$DEPLOYER_FOLDERNAME" | awk -F'-' '{print $2}' | xargs)

if [ -z $CONTROL_PLANE_NAME ]; then
	CONTROL_PLANE_NAME=$(echo "$DEPLOYER_FOLDERNAME" | cut -d'-' -f1-3)
	export $CONTROL_PLANE_NAME
fi

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$CONTROL_PLANE_NAME"
deployer_tfvars_file_name="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME"
library_tfvars_file_name="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME"

echo "Configuration file:                  $deployer_environment_file_name"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Control Plane Name:                  $CONTROL_PLANE_NAME"

if [ -f "${deployer_environment_file_name}" ]; then
	step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
fi

if [ -z "$step" ]; then
	step=0
fi

echo "Step:                                $step"

if [ 0 != "${step}" ]; then
	echo "##vso[task.logissue type=warning]Already prepared"
	print_banner "Deployer " "The deployer is already bootstrapped" "info"
	exit 0
fi

echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"
git checkout -q "$BUILD_SOURCEBRANCHNAME"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
if ! az extension list --query "[?contains(name, 'azure-devops')]" --output table; then
	az extension add --name azure-devops --output none --only-show-errors
fi
az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none --only-show-errors

echo -e "$green--- File Validations ---$reset"
if [ ! -f "$deployer_tfvars_file_name" ]; then
	echo -e "$bold_red--- File "$deployer_tfvars_file_name" was not found ---$reset"
	echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME was not found."
	exit 2
fi
if [ ! -f $library_tfvars_file_name ]; then
	echo -e "$bold_red--- File $library_tfvars_file_name  was not found ---$reset"
	echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME was not found."
	exit 2
fi

echo ""
echo "Agent:                               $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
if [ -n "$TF_VAR_agent_pat" ]; then
	echo "Deployer Agent PAT:                  IsDefined"
fi
if [ -n "$POOL" ]; then
	echo "Deployer Agent Pool:                 $POOL"
fi
echo ""

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")
if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

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

fi

export ARM_SUBSCRIPTION_ID
az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault")
if [ -n "$key_vault" ]; then
	echo "Deployer Key Vault:                  ${key_vault}"

	key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)

	if [ -z "${key_vault_id}" ]; then
		echo "##vso[task.logissue type=error]Key Vault $key_vault could not be found, trying to recover"
		key_vault=$(az keyvault list-deleted --query "[?name=='${key_vault}'].name | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)
		if [ -n "$key_vault" ]; then

			print_banner "$banner_title" "Key Vault $key_vault found in deleted state, recovering it" "info"

			if az keyvault recover --name "${key_vault}" --subscription "$ARM_SUBSCRIPTION_ID" --output none; then
				key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$ARM_SUBSCRIPTION_ID" --output tsv)
				if [ -n "${key_vault_id}" ]; then
					export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
					this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
					az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --subscription "$ARM_SUBSCRIPTION_ID" --only-show-errors --output none
				fi
			fi
		fi
	else
		export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --subscription "$ARM_SUBSCRIPTION_ID" --only-show-errors --output none

	fi
else
	echo "Deployer Key Vault:                  undefined"
fi

echo -e "$green--- Variables ---$reset"

if [ -z "${TF_VAR_ansible_core_version}" ]; then
	TF_VAR_ansible_core_version=2.16
	export TF_VAR_ansible_core_version
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" ]; then
	# shellcheck disable=SC2001
	# shellcheck disable=SC2005
	pass=${SYSTEM_COLLECTIONID//-/}
	echo "Unzipping state.zip"
	unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME"
fi

export TF_LOG_PATH=$CONFIG_REPO_PATH/.sap_deployment_automation/terraform.log
set +eu

msi_flag="  "

if [ "$USE_MSI" == "true" ]; then
	msi_flag=" --msi "
fi
if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_control_plane_v2.sh" \
	--deployer_parameter_file "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYER_FOLDERNAME/$DEPLOYER_TFVARS_FILENAME" \
	--library_parameter_file "${CONFIG_REPO_PATH}/LIBRARY/$LIBRARY_FOLDERNAME/$LIBRARY_TFVARS_FILENAME" \
	--subscription "$ARM_SUBSCRIPTION_ID" \
	--auto-approve --ado --only_deployer "${msi_flag}"; then
	return_code=$?
else
	return_code=$?
fi

print_banner "$banner_title - Preparation" "Deploy_control_plane_v2 returned: $return_code" "info"

set -eu

if [ 0 = $return_code ]; then
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_ID" "$APPLICATION_CONFIGURATION_ID"
	saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "$DEPLOYER_KEYVAULT"

	if [ "$USE_MSI" != "true" ]; then
		if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --environment "${ENVIRONMENT}" --vault ${DEPLOYER_KEYVAULT} \
			--region "${LOCATION}" --subscription "$ARM_SUBSCRIPTION_ID" --spn_id "$ARM_CLIENT_ID" --spn_secret "$ARM_CLIENT_SECRET" --tenant_id "$ARM_TENANT_ID" --ado; then
			return_code=$?
		else
			return_code=$?
			print_banner "$banner_title - Set secrets" "Set_secrets failed" "error"
		fi
	fi

fi

echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
added=0
cd "$CONFIG_REPO_PATH" || exit

# Pull changes
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

if [ -f ".sap_deployment_automation/$CONTROL_PLANE_NAME" ]; then
	git add ".sap_deployment_automation/$CONTROL_PLANE_NAME"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/deployer_tfvars_file_name" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/deployer_tfvars_file_name"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate" ]; then
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/.terraform/terraform.tfstate"
	added=1
fi

if [ -f "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate" ]; then
	sudo apt-get install zip -y
	pass=${SYSTEM_COLLECTIONID//-/}
	zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYER_FOLDERNAME/state" "DEPLOYER/$DEPLOYER_FOLDERNAME/terraform.tfstate"
	git add -f "DEPLOYER/$DEPLOYER_FOLDERNAME/state.zip"
	added=1
fi

if [ 1 = $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
	git commit -m "Added updates from Control Plane Deployment for $DEPLOYER_FOLDERNAME $LIBRARY_FOLDERNAME $BUILD_BUILDNUMBER [skip ci]"
	if ! git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=error]Failed to push changes to the repository."
	fi
fi

if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${CONTROL_PLANE_NAME}.md" ]; then
	if echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${CONTROL_PLANE_NAME}.md"; then
		echo ""
	fi
fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

exit $return_code

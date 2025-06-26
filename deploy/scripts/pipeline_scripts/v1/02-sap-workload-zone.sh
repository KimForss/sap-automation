#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

<<<<<<< HEAD
=======
echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"
>>>>>>> 591634d45 (Bring in the new scripts)
green="\e[1;32m"
reset="\e[0m"
bold_red="\e[1;31m"
cyan="\e[1;36m"

<<<<<<< HEAD
# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
grand_parent_directory="$(dirname "$parent_directory")"

SCRIPT_NAME="$(basename "$0")"

banner_title="Deploy Workload Zone"

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

WORKLOAD_ZONE_NAME=$(echo "$WORKLOAD_ZONE_FOLDERNAME" | cut -d'-' -f1-3)

echo "##vso[build.updatebuildnumber]Deploying the SAP Workload zone defined in $WORKLOAD_ZONE_FOLDERNAME"

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

echo -e "$cyan tfvarsFile: $tfvarsFile $reset"
echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

=======
#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"

DEBUG=false
if [ "$SYSTEM_DEBUG" = True ]; then
	set -x
	DEBUG=true
	echo "Environment variables:"
	printenv | sort
fi

export DEBUG
set -eu

tfvarsFile="LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME"

>>>>>>> 591634d45 (Bring in the new scripts)
if [ ! -f "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
	echo -e "$bold_red--- $WORKLOAD_ZONE_TFVARS_FILENAME was not found ---$reset"
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

if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "CONTROL_PLANE_NAME" "$CONTROL_PLANE_NAME"; then
	echo "Variable CONTROL_PLANE_NAME was added to the $VARIABLE_GROUP variable group."
else
	echo "##vso[task.logissue type=error]Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
	echo "Variable CONTROL_PLANE_NAME was not added to the $VARIABLE_GROUP variable group."
fi

if ! get_variable_group_id "$PARENT_VARIABLE_GROUP" "PARENT_VARIABLE_GROUP_ID"; then
	echo -e "$bold_red--- Variable group $PARENT_VARIABLE_GROUP not found ---$reset"
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP not found."
=======
echo -e "$green--- Checkout $BUILD_SOURCEBRANCHNAME ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BUILD_SOURCEBRANCHNAME"

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

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none

az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization="$SYSTEM_COLLECTIONURI" project="$SYSTEM_TEAMPROJECT" --output none

PARENT_VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$PARENT_VARIABLE_GROUP'].id | [0]")

if [ -z "${PARENT_VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $PARENT_VARIABLE_GROUP could not be found."
>>>>>>> 591634d45 (Bring in the new scripts)
	exit 2
fi
export PARENT_VARIABLE_GROUP_ID

<<<<<<< HEAD
deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$CONTROL_PLANE_NAME"
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$WORKLOAD_ZONE_NAME"

DEPLOYER_KEYVAULT=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "DEPLOYER_KEYVAULT")

if [ -z "$APPLICATION_CONFIGURATION_ID" ]; then
	APPLICATION_CONFIGURATION_ID=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_ID" "${deployer_environment_file_name}" "APPLICATION_CONFIGURATION_ID")
	APPLICATION_CONFIGURATION_NAME=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_ID" "$APPLICATION_CONFIGURATION_ID"; then
		echo "Variable APPLICATION_CONFIGURATION_ID was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable APPLICATION_CONFIGURATION_ID was not added to the $VARIABLE_GROUP variable group."
		echo "Variable APPLICATION_CONFIGURATION_ID was not added to the $VARIABLE_GROUP variable group."
	fi
	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "APPLICATION_CONFIGURATION_NAME" "$APPLICATION_CONFIGURATION_NAME"; then
		echo "Variable APPLICATION_CONFIGURATION_NAME was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable APPLICATION_CONFIGURATION_NAME was not added to the $VARIABLE_GROUP variable group."
		echo "Variable APPLICATION_CONFIGURATION_NAME was not added to the $VARIABLE_GROUP variable group."
	fi
fi

az account set --subscription "$ARM_SUBSCRIPTION_ID"

dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $1}')
LOCATION_CODE_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)
NETWORK_IN_FILENAME=$(echo $WORKLOAD_ZONE_FOLDERNAME | awk -F'-' '{print $3}')

deployer_tfstate_key=$CONTROL_PLANE_NAME.terraform.tfstate
export deployer_tfstate_key

landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
export landscape_tfstate_key

echo -e "${green}Deployment details:"
echo -e "-------------------------------------------------------------------------${reset}"

echo "CONTROL_PLANE_NAME:                  $CONTROL_PLANE_NAME"
echo "WORKLOAD_ZONE_NAME:                  $WORKLOAD_ZONE_NAME"
echo "Control plane environment file:      $deployer_environment_file_name"
echo "Workload Zone Environment file:      $workload_environment_file_name"
echo "Workload zone TFvars:                $WORKLOAD_ZONE_TFVARS_FILENAME"
if [ -n "$APPLICATION_CONFIGURATION_NAME" ]; then
	echo "APPLICATION_CONFIGURATION_NAME:      $APPLICATION_CONFIGURATION_NAME"
fi
echo ""

echo "Environment:                         $ENVIRONMENT"
echo "Environment in file:                 $ENVIRONMENT_IN_FILENAME"
echo "Location:                            $LOCATION"
echo "Location in file:                    $LOCATION_IN_FILENAME"
echo "Network:                             $NETWORK"
echo "Network in file:                     $NETWORK_IN_FILENAME"

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
	print_banner "$banner_title" "Environment mismatch" "error" "The environment setting in the tfvars file is not a part of the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
=======
VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$VARIABLE_GROUP'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
	echo "##vso[task.logissue type=error]Variable group $VARIABLE_GROUP could not be found."
	exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

printf -v tempval '%s id:' "$PARENT_VARIABLE_GROUP"
printf -v val '%-20s' "${tempval}"
echo "$val                 $PARENT_VARIABLE_GROUP_ID"

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

echo "Deployer Environment                 $DEPLOYER_ENVIRONMENT"
echo "Deployer Region                      $DEPLOYER_REGION"
echo "Workload TFvars                      $WORKLOAD_ZONE_TFVARS_FILENAME"
echo ""

echo "Agent pool:                          $THIS_AGENT"
echo "Organization:                        $SYSTEM_COLLECTIONURI"
echo "Project:                             $SYSTEM_TEAMPROJECT"
echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]The environment setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$ENVIRONMENT' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
<<<<<<< HEAD
	print_banner "$banner_title" "Location mismatch" "error" "The 'location' setting in the tfvars file is not represented in the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
=======
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]The location setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$LOCATION' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
<<<<<<< HEAD
	print_banner "$banner_title" "Naming mismatch" "error" "The 'network_logical_name' setting in the tfvars file is not a part of the $WORKLOAD_ZONE_TFVARS_FILENAME file name" "Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
=======
>>>>>>> 591634d45 (Bring in the new scripts)
	echo "##vso[task.logissue type=error]The network_logical_name setting in $WORKLOAD_ZONE_TFVARS_FILENAME '$NETWORK' does not match the $WORKLOAD_ZONE_TFVARS_FILENAME file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
	exit 2
fi

<<<<<<< HEAD
dos2unix -q "${workload_environment_file_name}"

if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	application_configuration_name=$(echo "$APPLICATION_CONFIGURATION_ID" | cut -d '/' -f 9)

	TF_VAR_management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
	export TF_VAR_management_subscription_id

	tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "${CONTROL_PLANE_NAME}")
	if [ -z "$tfstate_resource_id" ]; then
		echo "##vso[task.logissue type=warning]Key '${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId' was not found in the application configuration ( '$application_configuration_name' )."
	fi
	TF_VAR_tfstate_resource_id="$tfstate_resource_id"
	export TF_VAR_tfstate_resource_id
else
	echo "##vso[task.logissue type=warning]Variable APPLICATION_CONFIGURATION_ID was not defined."
	load_config_vars "${deployer_environment_file_name}" "tfstate_resource_id" "subscription"

	TF_VAR_spn_keyvault_id=$(az keyvault show --name "${DEPLOYER_KEYVAULT}" --query id --subscription "${ARM_SUBSCRIPTION_ID}" --out tsv)
	export TF_VAR_spn_keyvault_id
	TF_VAR_management_subscription_id=$(echo "$TF_VAR_spn_keyvault_id" | cut -d '/' -f 3)
	export TF_VAR_management_subscription_id

	TF_VAR_tfstate_resource_id="$tfstate_resource_id"
	export TF_VAR_tfstate_resource_id

fi

if [ -z "$tfstate_resource_id" ]; then
	echo "##vso[task.logissue type=error]Terraform state storage account resource id ('${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId') was not found in the application configuration ( '$application_configuration_name' nor was it defined in ${deployer_environment_file_name})."
	exit 2
fi

terraform_storage_account_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 9)
terraform_storage_account_resource_group_name=$(echo "$tfstate_resource_id" | cut -d '/' -f 5)
terraform_storage_account_subscription_id=$(echo "$tfstate_resource_id" | cut -d '/' -f 3)

export terraform_storage_account_name
export terraform_storage_account_resource_group_name
export terraform_storage_account_subscription_id
export tfstate_resource_id

if [ -z "$tfstate_resource_id" ]; then
	tfstate_resource_id=$(az resource list --name "${terraform_storage_account_name}" --subscription "$terraform_storage_account_subscription_id" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
	export tfstate_resource_id
fi

print_banner "$banner_title" "Starting the deployment" "info"
cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then
	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file "$WORKLOAD_ZONE_TFVARS_FILENAME" --type sap_landscape \
		--control_plane_name "${CONTROL_PLANE_NAME}" --application_configuration_name "$APPLICATION_CONFIGURATION_NAME" \
		--workload_zone_name "${WORKLOAD_ZONE_NAME}" --storage_accountname "$terraform_storage_account_name" \
		--ado --auto-approve; then
		return_code=$?
		print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME succeeded" "success"
	else
		return_code=$?
		print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME failed" "error"

		echo "##vso[task.logissue type=error]Terraform apply failed."
	fi
else
	if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer_v2.sh" --parameter_file "$WORKLOAD_ZONE_TFVARS_FILENAME" --type sap_landscape \
		--control_plane_name "${CONTROL_PLANE_NAME}" --workload_zone_name "${WORKLOAD_ZONE_NAME}" --storage_accountname "$terraform_storage_account_name" \
		--ado --auto-approve; then
		return_code=$?
		print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME succeeded" "success"
	else
		return_code=$?
		print_banner "$banner_title" "Deployment of $WORKLOAD_ZONE_NAME failed" "error"

		echo "##vso[task.logissue type=error]Terraform apply failed."
	fi

fi
echo "Return code from deployment:         ${return_code}"

set +o errexit

echo -e "$green--- Pushing the changes to the repository ---$reset"
# Pull changes if there are other deployment jobs
git pull -q origin "$BUILD_SOURCEBRANCHNAME"

added=0

if [ -f .terraform/terraform.tfstate ]; then
	git add -f .terraform/terraform.tfstate
	added=1
fi

if [ -f ".sap_deployment_automation/${WORKLOAD_ZONE_NAME}" ]; then
	git add ".sap_deployment_automation/${WORKLOAD_ZONE_NAME}"
=======
deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$DEPLOYER_ENVIRONMENT$DEPLOYER_REGION"
echo "Deployer Environment File:           $deployer_environment_file_name"
if [ ! -f "${deployer_environment_file_name}" ]; then
	echo -e "$bold_red--- $DEPLOYER_ENVIRONMENT$DEPLOYER_REGION was not found ---$reset"
	echo "##vso[task.logissue type=error]Control plane configuration file $DEPLOYER_ENVIRONMENT$DEPLOYER_REGION was not found."
	exit 2
fi
workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
echo "Workload Zone Environment File:      $workload_environment_file_name"
touch "$workload_environment_file_name"

echo -e "$green--- Read parameter values ---$reset"

dos2unix -q "${deployer_environment_file_name}"
dos2unix -q "${workload_environment_file_name}"

landscape_tfstate_key=$WORKLOAD_ZONE_FOLDERNAME.terraform.tfstate
export landscape_tfstate_key

deployer_tfstate_key=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${workload_environment_file_name}" "deployer_tfstate_key")
export deployer_tfstate_key

key_vault=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "DEPLOYER_KEYVAULT" "${deployer_environment_file_name}" "keyvault")
export key_vault

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA")
export REMOTE_STATE_SA

STATE_SUBSCRIPTION=$(getVariableFromVariableGroup "${PARENT_VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${deployer_environment_file_name}" "STATE_SUBSCRIPTION")
export STATE_SUBSCRIPTION

workload_key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Workload_Key_Vault" "${workload_environment_file_name}" "workloadkeyvault")
export workload_key_vault

echo "Deployer statefile:                  $deployer_tfstate_key"
echo "Workload Key vault:                  ${workload_key_vault}"
echo "Target subscription                  $ARM_SUBSCRIPTION_ID"

echo "Terraform state file subscription:   $STATE_SUBSCRIPTION"
echo "Terraform state file storage account:$REMOTE_STATE_SA"

if [ -n "$key_vault" ]; then
	echo "Deployer Key Vault:                  ${key_vault}"
	key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" --subscription "$STATE_SUBSCRIPTION" --output tsv)

	export TF_VAR_spn_keyvault_id=${key_vault_id}
else
	echo "Deployer Key Vault:                  undefined"
fi

secrets_set=1
az account set --subscription $STATE_SUBSCRIPTION
echo -e "$green --- Set secrets ---$reset"

if [ "$USE_MSI" != "true" ]; then
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --workload --vault "${key_vault}" --environment "${ENVIRONMENT}" \
		--region "${LOCATION}" --subscription "$ARM_SUBSCRIPTION_ID" --spn_id "$ARM_CLIENT_ID" --spn_secret "${ARM_CLIENT_SECRET}" \
		--tenant_id "$ARM_TENANT_ID" --keyvault_subscription "$STATE_SUBSCRIPTION"
else
	"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/set_secrets.sh" --workload --vault "${key_vault}" --environment "${ENVIRONMENT}" \
		--region "${LOCATION}" --subscription "$ARM_SUBSCRIPTION_ID" --keyvault_subscription "$STATE_SUBSCRIPTION" --msi
fi
secrets_set=$?
echo "Set Secrets returned: $secrets_set"

tfstate_resource_id=$(az resource list --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
export tfstate_resource_id

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
		echo " ##vso[task.logissue type=warning]Service Principal $ARM_CLIENT_ID does not have 'User Access Administrator' permissions. Please ensure that the service principal $ARM_CLIENT_ID has permissions on the Terrafrom state storage account and if needed on the Private DNS zone and the source management network resource"
	fi
fi

az account show --query name
printenv | grep ARM | sort

echo -e "$green--- Deploy the workload zone ---$reset"
cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/install_workloadzone.sh" --parameterfile "$WORKLOAD_ZONE_TFVARS_FILENAME" \
	--deployer_environment "$DEPLOYER_ENVIRONMENT" --subscription "$ARM_SUBSCRIPTION_ID" \
	--deployer_tfstate_key "${deployer_tfstate_key}" --keyvault "${key_vault}" --storageaccountname "${REMOTE_STATE_SA}" \
	--state_subscription "${STATE_SUBSCRIPTION}" --auto-approve --ado --msi; then
	return_code=$?
	echo "##vso[task.logissue type=warning]Workload zone deployment completed successfully."
else
	return_code=$?
	echo "##vso[task.logissue type=error]Workload zone deployment failed."
	exit 1
fi

echo "Return code from deployment:         ${return_code}"
cd "$CONFIG_REPO_PATH" || exit

workload_environment_file_name=".sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"

if [ -f "${workload_environment_file_name}" ]; then
	workload_key_vault=$(grep "workloadkeyvault=" "${workload_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	export workload_key_vault
	echo "Workload zone key vault:             ${workload_key_vault}"

	workload_prefix=$(grep "workload_zone_prefix=" "${workload_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
	export workload_prefix
	echo "Workload zone prefix:                ${workload_prefix}"

fi

prefix="${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"

echo -e "$green--- Adding variables to the variable group" "$VARIABLE_GROUP" "---$reset"
if [ -n "${VARIABLE_GROUP_ID}" ]; then

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${REMOTE_STATE_SA}"; then
		echo "Variable Terraform_Remote_Storage_Account_Name was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Account_Name was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Terraform_Remote_Storage_Account_Name was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Subscription" "${STATE_SUBSCRIPTION}"; then
		echo "Variable Terraform_Remote_Storage_Subscription was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Terraform_Remote_Storage_Subscription was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Terraform_Remote_Storage_Subscription was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "${deployer_tfstate_key}"; then
		echo "Variable Deployer_State_FileName was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Deployer_State_FileName was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${key_vault}"; then
		echo "Variable Deployer_Key_Vault was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable Deployer_Key_Vault was not added to the $VARIABLE_GROUP variable group."
		echo "Variable Deployer_Key_Vault was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Key_Vault" "${workload_key_vault}"; then
		echo "Variable ${prefix}Workload_Key_Vault was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ${prefix}Workload_Key_Vault was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ${prefix}Workload_Key_Vault was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Secret_Prefix" "${ENVIRONMENT}-${LOCATION_CODE_IN_FILENAME}-${NETWORK}"; then
		echo "Variable ${prefix}Workload_Secret_Prefix was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ${prefix}Workload_Secret_Prefix was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ${prefix}Workload_Secret_Prefix was not added to the $VARIABLE_GROUP variable group."
	fi

	if saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "${prefix}Workload_Zone_State_FileName" "${landscape_tfstate_key}"; then
		echo "Variable ${prefix}Workload_Zone_State_FileName was added to the $VARIABLE_GROUP variable group."
	else
		echo "##vso[task.logissue type=error]Variable ${prefix}Workload_Zone_State_FileName was not added to the $VARIABLE_GROUP variable group."
		echo "Variable ${prefix}Workload_Zone_State_FileName was not added to the $VARIABLE_GROUP variable group."
	fi

fi

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
if [ -f ".sap_deployment_automation/${prefix}" ]; then
	git add ".sap_deployment_automation/${prefix}"
	added=1
fi

cd "$CONFIG_REPO_PATH/LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME" || exit
normalizedName=$(echo "${workload_prefix}" | tr -d '-')

if [ -f "${workload_prefix}.md" ]; then

	mv "${workload_prefix}.md" "${normalizedName}.md"
	git add "${normalizedName}.md"
	# echo "##vso[task.uploadsummary]./${normalizedName}.md"
>>>>>>> 591634d45 (Bring in the new scripts)
	added=1
fi

if [ -f "$WORKLOAD_ZONE_TFVARS_FILENAME" ]; then
<<<<<<< HEAD
	git add "$WORKLOAD_ZONE_TFVARS_FILENAME"
=======
	git add -f "$WORKLOAD_ZONE_TFVARS_FILENAME"
	added=1
fi

if [ -f "/.terraform/terraform.tfstate" ]; then
	git add -f "LANDSCAPE/$WORKLOAD_ZONE_FOLDERNAME/.terraform/terraform.tfstate"
>>>>>>> 591634d45 (Bring in the new scripts)
	added=1
fi

if [ 1 == $added ]; then
	git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
	git config --global user.name "$BUILD_REQUESTEDFOR"
<<<<<<< HEAD
	git commit -m "Added updates from SAP workload zone deployment of $WORKLOAD_ZONE_FOLDERNAME for $BUILD_BUILDNUMBER [skip ci]"

	if git -c http.extraheader="AUTHORIZATION: bearer SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Changes from SAP deployment of $WORKLOAD_ZONE_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi
fi

print_banner "$banner_title" "Exiting $SCRIPT_NAME" "info"

=======
	git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER of $WORKLOAD_ZONE_FOLDERNAME [skip ci]"
	if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BUILD_SOURCEBRANCHNAME" --force-with-lease; then
		echo "##vso[task.logissue type=warning]Workload deployment $WORKLOAD_ZONE_FOLDERNAME pushed to $BUILD_SOURCEBRANCHNAME"
	else
		echo "##vso[task.logissue type=error]Failed to push changes to $BUILD_SOURCEBRANCHNAME"
	fi

fi

>>>>>>> 591634d45 (Bring in the new scripts)
exit $return_code

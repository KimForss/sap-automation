#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#colors for terminal
bold_red="\e[1;31m"

reset_formatting="\e[0m"

# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

# Fail on any error, undefined variable, or pipeline failure

# Enable debug mode if DEBUG is set to 'true'
if [[ "${DEBUG:-false}" == 'true' ]]; then
	# Enable debugging
	# Exit on error
	set -euox pipefail
	echo "Environment variables:"
	printenv | sort
fi

# Constants
readonly script_directory="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

SCRIPT_NAME="$(basename "$0")"

if printenv "CONFIG_REPO_PATH"; then
	CONFIG_DIR="${CONFIG_REPO_PATH}/.sap_deployment_automation"
else
	echo -e "${bold_red}CONFIG_REPO_PATH is not set${reset_formatting}"
	exit 1
fi

if printenv "TEST_ONLY"; then
	TEST_ONLY="${TEST_ONLY}"
else
	TEST_ONLY="false"
fi

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$path
fi

function show_help {
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   This file contains the logic to deploy the different systems                        #"
	echo "#   The script experts the following exports:                                           #"
	echo "#                                                                                       #"
	echo "#   ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                      #"
	echo "#   SAP_AUTOMATION_REPO_PATH the path to the folder containing the cloned sap-automation#"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   The script will persist the parameters needed between the executions in the         #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: installer.sh                                                                 #"
	echo "#    -p or --parameterFilename           parameter file                                     #"
	echo "#    -t or --type                         type of system to remove                      #"
	echo "#                                         valid options:                                #"
	echo "#                                           sap_deployer                                #"
	echo "#                                           sap_library                                 #"
	echo "#                                           sap_landscape                               #"
	echo "#                                           sap_system                                  #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#                                                                                       #"
	echo "#    -o or --storageaccountname      Storage account name for state file                #"
	echo "#    -d or --deployer_tfstate_key    Deployer terraform state file name                 #"
	echo "#    -l or --landscape_tfstate_key     Workload zone terraform state file name          #"
	echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
	echo "#    -i or --auto-approve            Silent install                                     #"
	echo "#    -h or --help                    Show help                                          #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
	echo "#      --parameterFilename DEV-WEEU-SAP01-X00 \                                             #"
	echo "#      --type sap_system                                                                #"
	echo "#      --auto-approve                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	return 0
}

function missing {
	printf -v val %-.40s "$1"
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables: ${val}!!!              #"
	echo "#                                                                                       #"
	echo "#   Please export the folloing variables:                                               #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
	echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#      terraform_storage_account_resource_group_name (resource group name for storage account containing state files) #"
	echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
	return 0
}

# Function to source helper scripts
source_helper_scripts() {
	local -a helper_scripts=("$@")
	for script in "${helper_scripts[@]}"; do
		if [[ -f "$script" ]]; then
			# shellcheck source=/dev/null
			source "$script"
		else
			echo "Helper script not found: $script"
			exit 1
		fi
	done
}

# Function to parse command line arguments
function parse_arguments() {
	local input_opts
	input_opts=$(getopt -n installer_v2 -o p:t:o:d:l:s:g:c:w:ahif --longoptions type:,parameter_file:,storage_accountname:,deployer_tfstate_key:,landscape_tfstate_key:,state_subscription:,application_configuration_id:,control_plane_name:,workload_zone_name:,ado,auto-approve,force,help -- "$@")
	is_input_opts_valid=$?

	if [[ "${is_input_opts_valid}" != "0" ]]; then
		show_help
		return 1
	fi

	eval set -- "$input_opts"
	while true; do
		case "$1" in
		-a | --ado)
			called_from_ado=1
			approve="--auto-approve"
			TF_IN_AUTOMATION=true
			export TF_IN_AUTOMATION
			shift
			;;
		-d | --deployer_tfstate_key)
			deployer_tfstate_key="$2"
			shift 2
			;;
		-c | --control_plane_name)
			CONTROL_PLANE_NAME="$2"
			shift 2
			;;
		-g | --application_configuration_id)
			APPLICATION_CONFIGURATION_ID="$2"
			shift 2
			;;
		-l | --landscape_tfstate_key)
			landscape_tfstate_key="$2"
			shift 2
			;;
		-o | --storage_accountname)
			terraform_storage_account_name="$2"
			shift 2
			;;
		-p | --parameter_file)
			parameterFilename="$2"
			shift 2
			;;
		-s | --state_subscription)
			terraform_storage_account_subscription_id="$2"
			shift 2
			;;
		-t | --type)
			deployment_system="$2"
			shift 2
			;;
		-w | --workload_zone_name)
			WORKLOAD_ZONE_NAME="$2"
			shift 2
			;;
		-f | --force)
			force=1
			shift
			;;
		-i | --auto-approve)
			approve="--auto-approve"
			shift
			;;
		-h | --help)
			show_help
			return 3
			;;
		--)
			shift
			break
			;;
		esac
	done

	# Validate required parameters

	parameterfile_name=$(basename "${parameterFilename}")
	param_dirname=$(dirname "${parameterFilename}")

	if [ "${param_dirname}" != '.' ]; then
		print_banner "Installer" "Please run this command from the folder containing the parameter file" "error"
	fi

	if [ ! -f "${parameterfile_name}" ]; then
		print_banner "Installer" "Parameter file does not exist: ${parameterFilename}" "error"
	fi

	[[ -z "$CONTROL_PLANE_NAME" ]] && {
		print_banner "Installer" "control_plane_name is required" "error"
		return 1
	}

	[[ -z "$APPLICATION_CONFIGURATION_ID" ]] && {
		print_banner "Installer" "application_configuration_id is required" "error"
		return 1
	}

	[[ -z "$deployment_system" ]] && {
		print_banner "Installer" "type is required" "error"
		return 1
	}

	if [ -z $CONTROL_PLANE_NAME ] && [ -n "$deployer_tfstate_key" ]; then
		CONTROL_PLANE_NAME=$(echo $deployer_tfstate_key | cut -d'-' -f1-3)
	fi

	if [ -n "$CONTROL_PLANE_NAME" ]; then
		deployer_tfstate_key="${CONTROL_PLANE_NAME}-INFRASTRUCTURE.terraform.tfstate"
	fi

	if [ "${deployment_system}" == sap_system ] || [ "${deployment_system}" == sap_landscape ]; then
		if [ -n "$WORKLOAD_ZONE_NAME" ]; then
			landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
		else
			WORKLOAD_ZONE_NAME=$(echo $landscape_tfstate_key | cut -d'-' -f1-3)

			if [ -z $WORKLOAD_ZONE_NAME ] && [ -n "$landscape_tfstate_key" ]; then
				WORKLOAD_ZONE_NAME=$(echo $landscape_tfstate_key | cut -d'-' -f1-3)
			fi
		fi
	fi

	if [ "${deployment_system}" == sap_system ]; then
		if [ -z "${landscape_tfstate_key}" ]; then
			if [ 1 != $called_from_ado ]; then
				read -r -p "Workload terraform statefile name: " landscape_tfstate_key
				save_config_var "landscape_tfstate_key" "${system_config_information}"
			else
				print_banner "Installer" "Workload terraform statefile name is required" "error"
				unset TF_DATA_DIR
				return 2
			fi
		else
			TF_VAR_landscape_tfstate_key="${landscape_tfstate_key}"
			export TF_VAR_landscape_tfstate_key
			landscape_tfstate_key_exists=true
		fi
	fi

	if [ "${deployment_system}" != sap_deployer ]; then
		if [ -z "${deployer_tfstate_key}" ]; then
			if [ 1 != $called_from_ado ]; then
				read -r -p "Deployer terraform state file name: " deployer_tfstate_key
				save_config_var "deployer_tfstate_key" "${system_config_information}"
			else
				print_banner "Installer" "Deployer terraform state file name is required" "error"
				unset TF_DATA_DIR
				return 2
			fi
		fi
	fi

	if [ -n "${deployer_tfstate_key}" ]; then
		TF_VAR_deployer_tfstate_key="${deployer_tfstate_key}"
		export TF_VAR_deployer_tfstate_key
	fi

	# Check that the exports ARM_SUBSCRIPTION_ID and SAP_AUTOMATION_REPO_PATH are defined
	if ! validate_exports; then
		return $?
	fi

	# Check that Terraform and Azure CLI is installed
	if ! validate_dependencies; then
		return $?
	fi

	# Check that parameter files have environment and location defined
	if ! validate_key_parameters "$parameterFilename"; then
		return $?
	fi

	if [ $deployment_system == sap_system ] || [ $deployment_system == sap_landscape ]; then
		system_config_information="${CONFIG_DIR}/${WORKLOAD_ZONE_NAME}"
		touch "${system_config_information}"
		save_config_vars "${system_config_information}" landscape_tfstate_key_exists

		# network_logical_name=$(echo $WORKLOAD_ZONE_NAME | cut -d'-' -f3)
	else
		system_config_information="${CONFIG_DIR}/${CONTROL_PLANE_NAME}"
		touch "${system_config_information}"
		# management_network_logical_name=$(echo $CONTROL_PLANE_NAME | cut -d'-' -f3)
	fi
	save_config_vars "${system_config_information}" deployer_tfstate_key APPLICATION_CONFIGURATION_ID CONTROL_PLANE_NAME

	region=$(echo "${region}" | tr "[:upper:]" "[:lower:]")
	if valid_region_name "${region}"; then
		# Convert the region to the correct code
		get_region_code "${region}"
	else
		echo "Invalid region: $region"
		return 2
	fi

	return 0

}

# Function to retrieve data from Azure App Configuration
function retrieve_parameters() {

	TF_VAR_control_plane_name="${CONTROL_PLANE_NAME}"
	export TF_VAR_control_plane_name

	if is_valid_id "$APPLICATION_CONFIGURATION_ID" "/providers/Microsoft.AppConfiguration/configurationStores/"; then

		tfstate_resource_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_TerraformRemoteStateStorageAccountId" "$CONTROL_PLANE_NAME")
		TF_VAR_tfstate_resource_id=$tfstate_resource_id
		export TF_VAR_tfstate_resource_id

		terraform_storage_account_name=$(echo $tfstate_resource_id | cut -d'/' -f9)
		export terraform_storage_account_name

		terraform_storage_account_resource_group_name=$(echo $tfstate_resource_id | cut -d'/' -f5)
		export terraform_storage_account_resource_group_name

		terraform_storage_account_subscription_id=$(echo $tfstate_resource_id | cut -d'/' -f3)
		export terraform_storage_account_subscription_id

		TF_VAR_deployer_kv_user_arm_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultResourceId" "$CONTROL_PLANE_NAME")
		export TF_VAR_spn_keyvault_id="${TF_VAR_deployer_kv_user_arm_id}"

		keyvault=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_KeyVaultName" "${CONTROL_PLANE_NAME}")
		export keyvault

		management_subscription_id=$(getVariableFromApplicationConfiguration "$APPLICATION_CONFIGURATION_ID" "${CONTROL_PLANE_NAME}_SubscriptionId" "${CONTROL_PLANE_NAME}")
		TF_VAR_management_subscription_id=${management_subscription_id}
		export TF_VAR_management_subscription_id
	else
		if [ -z "$terraform_storage_account_name" ]; then
			if [ -f "${param_dirname}/.terraform/terraform.tfstate" ]; then
				local_backend=$(grep "\"type\": \"azurerm\"" .terraform/terraform.tfstate || true)
				if [ -n "${local_backend}" ]; then

					terraform_storage_account_subscription_id=$(grep -m1 "subscription_id" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d '", \r' | xargs || true)
					terraform_storage_account_name=$(grep -m1 "storage_account_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
					terraform_storage_account_resource_group_name=$(grep -m1 "resource_group_name" "${param_dirname}/.terraform/terraform.tfstate" | cut -d ':' -f2 | tr -d ' ",\r' | xargs || true)
					tfstate_resource_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
				fi
			else
				load_config_vars "${system_config_information}" \
					tfstate_resource_id DEPLOYER_KEYVAULT

				TF_VAR_spn_keyvault_id=$(az keyvault show --name "${DEPLOYER_KEYVAULT}" --query id --subscription "${ARM_SUBSCRIPTION_ID}" --out tsv)
				export TF_VAR_spn_keyvault_id

				export TF_VAR_tfstate_resource_id
				terraform_storage_account_name=$(echo $tfstate_resource_id | cut -d'/' -f9)
				export terraform_storage_account_name

				terraform_storage_account_resource_group_name=$(echo $tfstate_resource_id | cut -d'/' -f5)
				export terraform_storage_account_resource_group_name

				terraform_storage_account_subscription_id=$(echo $tfstate_resource_id | cut -d'/' -f3)
				export terraform_storage_account_subscription_id
			fi
		else
			terraform_storage_account_subscription_id=$(az storage account show --name "${terraform_storage_account_name}" --query id --out tsv | cut -d'/' -f3)
			export terraform_storage_account_subscription_id

		fi
	fi

}

function persist_files() {
	#################################################################################
	#                                                                               #
	#                           Copy tfvars to storage account                      #
	#                                                                               #
	#################################################################################

	print_banner "Installer" "Backup tfvars to storage account" "info"

	useSAS=$(az storage account show --name "${terraform_storage_account_name}" --query allowSharedKeyAccess --subscription "${terraform_storage_account_subscription_id}" --resource-group "${terraform_storage_account_resource_group_name}" --out tsv)
	auth_flag=login

	if [ "$useSAS" = "true" ]; then
		auth_flag=key
		echo "Storage Account authentication:      key"
		container_exists=$(az storage container exists --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --only-show-errors --query exists)
	else
		echo "Storage Account authentication:      Entra ID"
		container_exists=$(az storage container exists --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --only-show-errors --query exists --auth-mode login)
	fi

	if [ "${container_exists}" == "false" ]; then
		az storage container create --subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --name tfvars --auth-mode "$auth_flag" --only-show-errors
	fi

	az storage blob upload --file "${parameterFilename}" --container-name tfvars/"${state_path}"/"${key}" --name "${parameterFilename}" \
		--subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --auth-mode "$auth_flag" --no-progress --overwrite --only-show-errors --output none

	if [ -f .terraform/terraform.tfstate ]; then
		az storage blob upload --file .terraform/terraform.tfstate --container-name "tfvars/${state_path}/${key}/.terraform" --name terraform.tfstate \
			--subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --auth-mode "$auth_flag" --no-progress --overwrite --only-show-errors --output none
	fi
	if [ "${deployment_system}" == sap_system ]; then
		if [ -f sap-parameters.yaml ]; then
			echo "Uploading the yaml files from ${param_dirname} to the storage account"
			az storage blob upload --file sap-parameters.yaml --container-name tfvars/"${state_path}"/"${key}" --name sap-parameters.yaml \
				--subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --auth-mode "$auth_flag" --no-progress --overwrite --only-show-errors --output none
		fi

		hosts_file=$(ls *_hosts.yaml)
		az storage blob upload --file "${hosts_file}" --container-name tfvars/"${state_path}"/"${key}" --name "${hosts_file}" \
			--subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --auth-mode "$auth_flag" --no-progress --overwrite --only-show-errors --output none

	fi

	if [ "${deployment_system}" == sap_landscape ]; then
		az storage blob upload --file "${system_config_information}" --container-name tfvars/.sap_deployment_automation --name "${WORKLOAD_ZONE_NAME}" \
			--subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --auth-mode "$auth_flag" --no-progress --overwrite --only-show-errors --output none
	fi
	if [ "${deployment_system}" == sap_library ]; then
		deployer_config_information="${CONFIG_DIR}/${CONTROL_PLANE_NAME}"
		az storage blob upload --file "${deployer_config_information}" --container-name tfvars/.sap_deployment_automation --name "${CONTROL_PLANE_NAME}" \
			--subscription "${terraform_storage_account_subscription_id}" --account-name "${terraform_storage_account_name}" --auth-mode "$auth_flag" --no-progress --overwrite --only-show-errors --output none
	fi

}

function test_for_removal() {
	local local_return_code=0
	local file_name=$2
	if [ -f "$file_name" ]; then
		local -a helper_scripts=("$@")
		for resource in "${resources[@]}"; do
			moduleId=$(echo "$resource" | cut -d'~' -f1)
			description=$(echo "$resource" | cut -d'~' -f2)
			if ! testIfResourceWouldBeRecreated "$moduleId" $file_name "$description"; then
				fatal_errors=1
				local_return_code=1
			fi
		done
	fi
	return $local_return_code
}

function sdaf_installer() {
	landscape_tfstate_key=""
	landscape_tfstate_key_exists=false
	called_from_ado=0
	extra_vars=""
	WORKLOAD_ZONE_NAME=""
	local green="\e[0;32m"
	local reset="\e[0m"

	# Define an array of helper scripts
	helper_scripts=(
		"${script_directory}/helpers/script_helpers.sh"
		"${script_directory}/deploy_utils.sh"
	)

	# Call the function with the array
	source_helper_scripts "${helper_scripts[@]}"

	# Parse command line arguments
	if ! parse_arguments "$@"; then
		return $?
	fi

	if ! retrieve_parameters; then
		return $?
	fi

	parallelism=10

	#Provide a way to limit the number of parallel tasks for Terraform
	if printenv "TF_PARALLELLISM"; then
		parallelism=$TF_PARALLELLISM
	fi

	echo ""
	echo -e "${green}Deployment information:"
	echo -e "-------------------------------------------------------------------------------$reset"
	echo "Parameter file:                      $parameterFilename"
	echo "Current directory:                   $(pwd)"
	echo "Control Plane name:                  ${CONTROL_PLANE_NAME}"
	if [ -n "${WORKLOAD_ZONE_NAME}" ]; then
		echo "Workload zone name:                  ${WORKLOAD_ZONE_NAME}"
		landscape_tfstate_key="${WORKLOAD_ZONE_NAME}-INFRASTRUCTURE.terraform.tfstate"
	fi
	key=$(echo "${parameterfile_name}" | cut -d. -f1)

	echo "Configuration file:                  $system_config_information"
	echo "Deployment region:                   $region"
	echo "Deployment region code:              $region_code"
	echo "Target subscription:                 $ARM_SUBSCRIPTION_ID"

	if [ "$DEBUG" = True ]; then
		print_banner "Installer" "Enabling debug mode" "info"
		echo "Azure login info:"
		az account show --query user --output table
		TF_LOG=DEBUG
		export TF_LOG
		echo ""
		printenv | grep ARM_
	fi

	if [ 1 == $called_from_ado ]; then
		this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
		export TF_VAR_Agent_IP=$this_ip
		echo "Agent IP:                            $this_ip"
	fi

	# Terraform Plugins
	if checkIfCloudShell; then
		mkdir -p "${HOME}/.terraform.d/plugin-cache"
		export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
	else
		if [ ! -d /opt/terraform/.terraform.d/plugin-cache ]; then
			sudo mkdir -p /opt/terraform/.terraform.d/plugin-cache
			sudo chown -R "$USER" /opt/terraform
		fi
		export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
	fi

	param_dirname=$(pwd)
	export TF_DATA_DIR="${param_dirname}/.terraform"

	var_file="${param_dirname}"/"${parameterFilename}"

	if [ -f terraform.tfvars ]; then
		extra_vars="-var-file=${param_dirname}/terraform.tfvars"
	else
		extra_vars=""
	fi

	current_subscription_id=$(az account show --query id -o tsv)

	if [[ -n "$terraform_storage_account_subscription_id" ]] && [[ "$terraform_storage_account_subscription_id" != "$current_subscription_id" ]]; then
		print_banner "Installer" "Changing the subscription to: $terraform_storage_account_subscription_id" "info"
		az account set --sub "${terraform_storage_account_subscription_id}"

		return_code=$?
		if [ 0 != $return_code ]; then
			print_banner "Installer" "The deployment account (MSI or SPN) does not have access to: $terraform_storage_account_subscription_id" "ption_id}"
			exit $return_code
		fi

		az account set --sub "${current_subscription_id}"

	fi

	terraform_module_directory="$SAP_AUTOMATION_REPO_PATH/deploy/terraform/run/${deployment_system}"
	cd "${param_dirname}" || exit

	if [ ! -d "${terraform_module_directory}" ]; then

		printf -v val %-40.40s "$deployment_system"
		print_banner "Installer" "Incorrect system deployment type specified: ${val}$" "error"
		exit 1
	fi

	# This is used to tell Terraform if this is a new deployment or an update
	deployment_parameter=""
	# This is used to tell Terraform the version information from the state file
	version_parameter=""

	export TF_DATA_DIR="${param_dirname}/.terraform"

	echo ""
	echo -e "${green}Terraform details:"
	echo -e "-------------------------------------------------------------------------${reset}"
	echo "Statefile subscription:              ${terraform_storage_account_subscription_id}"
	echo "Statefile storage account:           ${terraform_storage_account_name}"
	echo "Statefile resource group:            ${terraform_storage_account_resource_group_name}"
	echo "State file:                          ${key}.terraform.tfstate"
	echo "Target subscription:                 ${ARM_SUBSCRIPTION_ID}"
	echo "Deployer state file:                 ${deployer_tfstate_key}"
	echo "Workload zone state file:            ${landscape_tfstate_key}"
	echo "Current directory:                   $(pwd)"
	echo "Parallelism count:                   $parallelism"
	echo ""

	useSAS=$(az storage account show --name "${terraform_storage_account_name}" --resource-group "${terraform_storage_account_resource_group_name}" --subscription "${terraform_storage_account_subscription_id}" --query allowSharedKeyAccess --out tsv)

	if [ "$useSAS" = "true" ]; then
		echo "Storage Account Authentication:      Key"
		export ARM_USE_AZUREAD=false
	else
		echo "Storage Account Authentication:      Entra ID"
		export ARM_USE_AZUREAD=true
	fi

	TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
	export TF_VAR_subscription_id

	terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/
	export TF_DATA_DIR="${param_dirname}/.terraform"

	new_deployment=0

	az account set --subscription "${terraform_storage_account_subscription_id}"

	if [ ! -f .terraform/terraform.tfstate ]; then
		print_banner "Installer" "New deployment" "info"

		if ! terraform -chdir="${terraform_module_directory}" init -upgrade=true -input=false \
			--backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
			--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
			--backend-config "storage_account_name=${terraform_storage_account_name}" \
			--backend-config "container_name=tfstate" \
			--backend-config "key=${key}.terraform.tfstate"; then
			return_value=$?
			print_banner "Installer" "Terraform init failed." "error"
			return $return_value
		else
			return_value=$?
		fi

	else
		new_deployment=1

		if local_backend=$(grep "\"type\": \"local\"" .terraform/terraform.tfstate); then
			if [ -n "$local_backend" ]; then
				print_banner "Installer" "Migrating the state to Azure" "info"

				terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/bootstrap/${deployment_system}"/

				if ! terraform -chdir="${terraform_module_directory}" init -migrate-state --backend-config "path=${param_dirname}/terraform.tfstate"; then
					return_value=$?
					print_banner "Installer" "Terraform local init failed" "error"
					exit $return_value
				else
					return_value=$?
					print_banner "Installer" "Terraform local init succeeded" "success"
				fi
			fi

			terraform_module_directory="${SAP_AUTOMATION_REPO_PATH}/deploy/terraform/run/${deployment_system}"/

			if terraform -chdir="${terraform_module_directory}" init -force-copy \
				--backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
				--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
				--backend-config "storage_account_name=${terraform_storage_account_name}" \
				--backend-config "container_name=tfstate" \
				--backend-config "key=${key}.terraform.tfstate"; then
				return_value=$?
				print_banner "Installer" "Terraform init succeeded." "success"

				allParameters=$(printf " -var-file=%s %s " "${var_file}" "${extra_vars}")
			else
				return_value=$?
				print_banner "Installer" "Terraform init failed" "error"
				return $return_value
			fi
		else
			echo "Terraform state:                     remote"
			print_banner "Installer" "The system has already been deployed and the state file is in Azure" "info"

			if ! terraform -chdir="${terraform_module_directory}" init -force-copy -migrate-state \
				--backend-config "subscription_id=${terraform_storage_account_subscription_id}" \
				--backend-config "resource_group_name=${terraform_storage_account_resource_group_name}" \
				--backend-config "storage_account_name=${terraform_storage_account_name}" \
				--backend-config "container_name=tfstate" \
				--backend-config "key=${key}.terraform.tfstate"; then
				return_value=$?
				print_banner "Installer" "Terraform init failed." "error"
				return $return_value
			else
				return_value=$?
				print_banner "Installer" "Terraform init succeeded." "success"
			fi
		fi
	fi

	if [ 1 -eq "$new_deployment" ]; then
		if terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
			print_banner "Installer" "New deployment" "info"
			deployment_parameter=" -var deployment=new "
			new_deployment=0
		else
			print_banner "Installer" "Existing deployment was detected" "info"
			deployment_parameter=""
			new_deployment=0
		fi
	fi

	if [ 1 -eq $new_deployment ]; then
		deployed_using_version=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw automation_version | tr -d \" || true)
		if [ -z "${deployed_using_version}" ]; then
			print_banner "Installer" "The environment was deployed using an older version of the Terraform templates" "error" "Please inspect the output of Terraform plan carefully!"

			if [ 1 == $called_from_ado ]; then
				unset TF_DATA_DIR
				exit 1
			fi
			read -r -p "Do you want to continue Y/N? " ans
			answer=${ans^^}
			if [ "$answer" != 'Y' ]; then
				unset TF_DATA_DIR
				exit 1
			fi
		else
			version_parameter="-var terraform_template_version=${deployed_using_version}"

			print_banner "Installer" "Deployed using the Terraform templates version: $deployed_using_version" "info"

			# version_compare "${deployed_using_version}" "3.13.2.0"
			# older_version=$?
			# if [ 2 == $older_version ]; then
			# 	echo ""
			# 	echo "#########################################################################################"
			# 	echo "#                                                                                       #"
			# 	echo -e "#           $bold_red  Deployed using an older version $reset_formatting                                          #"
			# 	echo "#                                                                                       #"
			# 	echo "#########################################################################################"
			# 	echo ""
			# 	echo "##vso[task.logissue type=warning]Deployed using an older version ${deployed_using_version}. Performing state management operations"

			# fi
		fi
	fi

	# Default to use MSI
	credentialVariable=" -var use_spn=false "
	if printenv TF_VAR_use_spn; then
		use_spn=$(echo $TF_VAR_use_spn | tr "[:upper:]" "[:lower:]")
		if [ "$use_spn" == "true" ]; then
			credentialVariable=" -var use_spn=true "
		fi
	fi

	allParameters=$(printf " -var-file=%s %s %s %s %s" "${var_file}" "${extra_vars}" "${deployment_parameter}" "${version_parameter}" "${credentialVariable}")

	if terraform -chdir="$terraform_module_directory" plan $allParameters -input=false -detailed-exitcode -compact-warnings -no-color | tee plan_output.log; then
		return_value=${PIPESTATUS[0]}
	else
		return_value=${PIPESTATUS[0]}
	fi

	if [ 1 -eq $return_value ]; then
		print_banner "Installer" "Error when running plan" "error" "Terraform plan return code: $return_value"
		return $return_value
	else
		print_banner "Installer" "Terraform plan succeeded." "success" "Terraform plan return code: $return_value"
	fi

	if [ 2 -eq $return_value ]; then
		apply_needed=1
	else
		apply_needed=1
	fi

	state_path="SYSTEM"

	fatal_errors=0

	if [ "${deployment_system}" == sap_deployer ]; then
		state_path="DEPLOYER"

		if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
			DEPLOYER_KEYVAULT=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw deployer_kv_user_name | tr -d \")
			if [ -n "$DEPLOYER_KEYVAULT" ]; then
				save_config_var "DEPLOYER_KEYVAULT" "${system_config_information}"
			fi
		fi

	fi

	if [ "${deployment_system}" == sap_landscape ]; then
		state_path="LANDSCAPE"
		if [ $landscape_tfstate_key_exists == false ]; then
			save_config_vars "${system_config_information}" \
				landscape_tfstate_key
		fi
	fi

	if [ "${deployment_system}" == sap_library ]; then
		state_path="LIBRARY"
		if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then
			tfstate_resource_id=$(terraform -chdir="${terraform_module_directory}" output tfstate_resource_id | tr -d \")
			save_config_vars "${system_config_information}" \
				tfstate_resource_id
		fi

		# Define an array resources
		resources=(
			"module.sap_library.azurerm_storage_account.storage_sapbits~SAP Library Storage Account"
			"module.sap_library.azurerm_storage_container.storagecontainer_sapbits~SAP Library Storage Account container"
			"module.sap_library.azurerm_storage_account.storage_tfstate~Terraform State Storage Account"
			"module.sap_library.azurerm_storage_container.storagecontainer_sapbits~Terraform State Storage Account container"
		)

		# Call the function with the array
		if ! test_for_removal "${resources[@]}" "plan_output.log"; then
			fatal_errors=1
		fi
	fi

	if [ "${deployment_system}" == sap_system ]; then
		state_path="SYSTEM"

		# Define an array resources
		resources=(
			"module.hdb_node.azurerm_linux_virtual_machine.vm_dbnode~Database server(s)"
			"module.hdb_node.azurerm_managed_disk.data_disk~Database server disk(s)"
			"module.anydb_node.azurerm_windows_virtual_machine.dbserver~Database server(s)"
			"module.anydb_node.azurerm_linux_virtual_machine.dbserver~Database server(s)"
			"module.anydb_node.azurerm_managed_disk.disks~Database server disk(s)"
			"module.app_tier.azurerm_windows_virtual_machine.app~Application server(s)"
			"module.app_tier.azurerm_linux_virtual_machine.app~Application server(s)"
			"module.app_tier.azurerm_managed_disk.app~Application server disk(s)"
			"module.app_tier.azurerm_windows_virtual_machine.scs~SCS server(s)"
			"module.app_tier.azurerm_linux_virtual_machine.scs~SCS server(s)"
			"module.app_tier.azurerm_managed_disk.scs~SCS server disk(s)"
			"module.app_tier.azurerm_windows_virtual_machine.web~Web server(s)"
			"module.app_tier.azurerm_linux_virtual_machine.web~Web server(s)"
			"module.app_tier.azurerm_managed_disk.web~Web server disk(s)"
		)

		# Call the function with the array
		if ! test_for_removal "${resources[@]}" "plan_output.log"; then
			fatal_errors=1
		fi
	fi

	if [ "${deployment_system}" == sap_landscape ]; then
		state_path="SYSTEM"

		# Define an array resources
		resources=(
			"module.sap_landscape.azurerm_key_vault.kv_user~Workload zone key vault"
		)

		# Call the function with the array
		if ! test_for_removal "${resources[@]}" "plan_output.log"; then
			fatal_errors=1
		fi
	fi

	# apply_needed=1 - This is already set above line: 736 - 740

	if [ "${TEST_ONLY}" == "True" ]; then
		print_banner "Installer" "Running plan only. No deployment performed." "info"

		if [ $fatal_errors == 1 ]; then
			print_banner "Installer" "!!! Risk for Data loss !!!" "error" "Please inspect the output of Terraform plan carefully"
			exit 10
		fi
		exit 0
	fi

	if [ $fatal_errors == 1 ]; then
		apply_needed=0
		print_banner "Installer" "!!! Risk for Data loss !!!" "error" "Please inspect the output of Terraform plan carefully"
		if [ 1 == "$called_from_ado" ]; then
			unset TF_DATA_DIR
			echo ##vso[task.logissue type=error]Risk for data loss, Please inspect the output of Terraform plan carefully. Run manually from deployer
			exit 1
		fi

		if [ 1 == $force ]; then
			apply_needed=1
		else
			read -r -p "Do you want to continue with the deployment Y/N? " ans
			answer=${ans^^}
			if [ "$answer" == 'Y' ]; then
				apply_needed=true
			else
				unset TF_DATA_DIR
				exit 1
			fi
		fi

	fi

	if [ 1 == $apply_needed ]; then

		if [ -f error.log ]; then
			rm error.log
		fi
		if [ -f plan_output.log ]; then
			rm plan_output.log
		fi

		print_banner "Installer" "Running Terraform apply" "info"

		allParameters=$(printf " -var-file=%s %s %s %s %s %s" "${var_file}" "${extra_vars}" "${deployment_parameter}" "${version_parameter}" "${credentialVariable}" "${approve} ")
		allImportParameters=$(printf " -var-file=%s %s %s %s %s " "${var_file}" "${extra_vars}" "${deployment_parameter}" "${version_parameter}" "${credentialVariable}")

		if [ -n "${approve}" ]; then
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" -no-color -compact-warnings -json -input=false $allParameters | tee apply_output.json; then
				return_value=${PIPESTATUS[0]}
			else
				return_value=${PIPESTATUS[0]}
			fi

		else
			# shellcheck disable=SC2086
			if terraform -chdir="${terraform_module_directory}" apply -parallelism="${parallelism}" $allParameters; then
				return_value=$?
			else
				return_value=$?
			fi
		fi

		if [ $return_value -eq 1 ]; then
			print_banner "Installer" "Terraform apply failed" "error" "Terraform apply return code: $return_value"
		elif [ $return_value -eq 2 ]; then
			# return code 2 is ok
			print_banner "Installer" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
			return_value=0
		else
			print_banner "Installer" "Terraform apply succeeded" "success" "Terraform apply return code: $return_value"
			return_value=0
		fi

		if [ -f apply_output.json ]; then

			errors_occurred=$(jq 'select(."@level" == "error") | length' apply_output.json)

			if [[ -n $errors_occurred ]]; then
				if [ -n "${approve}" ]; then

					# shellcheck disable=SC2086
					if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
						return_value=$?
					else
						return_value=0
					fi

					sleep 10

					if [ -f apply_output.json ]; then
						# shellcheck disable=SC2086
						if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
							return_value=$?
						else
							return_value=0
						fi
					fi

					if [ -f apply_output.json ]; then
						# shellcheck disable=SC2086
						if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
							return_value=$?
						else
							return_value=0
						fi

					fi

					if [ -f apply_output.json ]; then
						# shellcheck disable=SC2086
						if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
							return_value=$?
						else
							return_value=0
						fi
					fi
					if [ -f apply_output.json ]; then
						# shellcheck disable=SC2086
						if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
							return_value=$?
						else
							return_value=0
						fi
					fi
					if [ -f apply_output.json ]; then
						# shellcheck disable=SC2086
						if ! ImportAndReRunApply "apply_output.json" "${terraform_module_directory}" "$allImportParameters" "$allParameters" $parallelism; then
							return_value=$?
						else
							return_value=0
						fi
					fi
				else
					return_value=10
				fi

			fi
		fi
	fi
	if [ -f apply_output.json ]; then
		rm apply_output.json
	fi

	persist_files

	if [ $DEBUG == True ]; then
		echo "Terraform state file:"
		terraform -chdir="${terraform_module_directory}" output -json
	fi

	if [ 0 -ne $return_value ]; then
		print_banner "Installer" "Errors during the apply phase" "error"
		unset TF_DATA_DIR
		return $return_value
	fi

	if [ "${deployment_system}" == sap_deployer ]; then

		# terraform -chdir="${terraform_module_directory}"  output
		if ! terraform -chdir="${terraform_module_directory}" output | grep "No outputs"; then

			deployer_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
			if [ -n "${deployer_random_id}" ]; then
				save_config_var "deployer_random_id" "${system_config_information}"
				custom_random_id="${deployer_random_id:0:3}"
				sed -i -e /"custom_random_id"/d "${parameterFilename}"
				printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"
			fi
		fi

		keyvault=$(terraform -chdir="${terraform_module_directory}" output -no-color deployer_kv_user_name | tr -d \")

		app_config_id=$(terraform -chdir="${terraform_module_directory}" output -no-color deployer_app_config_id | tr -d \")

		app_service_name=$(terraform -chdir="${terraform_module_directory}" output -no-color webapp_url_base | tr -d \")

		app_service_deployment=$(terraform -chdir="${terraform_module_directory}" output -no-color app_service_deployment | tr -d \")

		echo ""
		if [ 1 == $called_from_ado ]; then
			if [ -n "${app_config_id}" ]; then
				az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPLICATION_CONFIGURATION_ID.value")
				if [ -z "${az_var}" ]; then
					az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name APPLICATION_CONFIGURATION_ID --value "${app_config_id}" --output none --only-show-errors
				else
					az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name APPLICATION_CONFIGURATION_ID --value "${app_config_id}" --output none --only-show-errors
				fi
			fi
			if [ -n "${app_service_name}" ]; then
				az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "APPSERVICE_NAME.value")
				if [ -z "${az_var}" ]; then
					az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name APPSERVICE_NAME --value "${app_service_name}" --output none --only-show-errors
				else
					az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name APPSERVICE_NAME --value "${app_service_name}" --output none --only-show-errors
				fi
			fi

			if [ -n "${app_service_deployment}" ]; then
				az_var=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "HAS_APPSERVICE_DEPLOYED.value")
				if [ -z "${az_var}" ]; then
					az pipelines variable-group variable create --group-id "${VARIABLE_GROUP_ID}" --name HAS_APPSERVICE_DEPLOYED --value "${app_service_deployment}" --output none --only-show-errors
				else
					az pipelines variable-group variable update --group-id "${VARIABLE_GROUP_ID}" --name HAS_APPSERVICE_DEPLOYED --value "${app_service_deployment}" --output none --only-show-errors
				fi
			fi

		fi

	fi

	if [ "${deployment_system}" == sap_library ]; then
		terraform_storage_account_name=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw remote_state_storage_account_name | tr -d \")

		library_random_id=$(terraform -chdir="${terraform_module_directory}" output -no-color -raw random_id | tr -d \")
		if [ -n "${library_random_id}" ]; then
			save_config_var "library_random_id" "${system_config_information}"
			custom_random_id="${library_random_id:0:3}"
			sed -i -e /"custom_random_id"/d "${parameterFilename}"
			printf "# The parameter 'custom_random_id' can be used to control the random 3 digits at the end of the storage accounts and key vaults\ncustom_random_id=\"%s\"\n" "${custom_random_id}" >>"${var_file}"

		fi

	fi

	unset TF_DATA_DIR
	print_banner "Installer" "Deployment completed." "success" "Exiting $SCRIPT_NAME"

	exit 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	# Only run if script is executed directly, not when sourced
	if sdaf_installer "$@"; then
		echo "Script executed successfully."
		exit 0
	else
		echo "Script failed with exit code $?"
		exit 10
	fi

fi

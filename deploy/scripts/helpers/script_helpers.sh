#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#colors for terminal
bold_red_underscore="\e[1;4;31m"
bold_red="\e[1;31m"
cyan="\e[1;36m"
reset_formatting="\e[0m"

if [[ -f /etc/profile.d/deploy_server.sh ]]; then
	path=$(grep -m 1 "export PATH=" /etc/profile.d/deploy_server.sh | awk -F'=' '{print $2}' | xargs)
	export PATH=$PATH:$path
fi

function print_banner() {
	local title="$1"
	local message="$2"

	local length=${#message}
	if ((length % 2 == 0)); then
		message="$message "
	else
		message="$message"
	fi

	length=${#title}
	if ((length % 2 == 0)); then
		title="$title "
	else
		title="$title"
	fi

	local type="${3:-info}"
	local secondary_message="${4:-''}"

	length=${#secondary_message}
	if ((length % 2 == 0)); then
		secondary_message="$secondary_message "
	else
		secondary_message="$secondary_message"
	fi

	local boldred="\e[1;31m"
	local cyan="\e[1;36m"
	local green="\e[1;32m"
	local reset="\e[0m"
	local yellow="\e[0;33m"

	local color
	case "$type" in
	error)
		color="$boldred"
		;;
	success)
		color="$green"
		;;
	warning)
		color="$yellow"
		;;
	info)
		color="$cyan"
		;;
	*)
		color="$cyan"
		;;
	esac

	local width=80
	local padding_title=$(((width - ${#title}) / 2))
	local padding_message=$(((width - ${#message}) / 2))
	local padding_secondary_message=$(((width - ${#secondary_message}) / 2))

	local centered_title
	local centered_message
	centered_title=$(printf "%*s%s%*s" $padding_title "" "$title" $padding_title "")
	centered_message=$(printf "%*s%s%*s" $padding_message "" "$message" $padding_message "")

	echo ""
	echo -e "${color}"
	echo "#################################################################################"
	echo "#                                                                               #"
	echo -e "#${color}${centered_title}${reset}#"
	echo "#                                                                               #"
	echo -e "#${color}${centered_message}${reset}#"
	echo "#                                                                               #"
	if [ ${#secondary_message} -gt 3 ]; then
		local centered_secondary_message
		centered_secondary_message=$(printf "%*s%s%*s" $padding_secondary_message "" "$secondary_message" $padding_secondary_message "")
		echo -e "#${color}${centered_secondary_message}${reset}#"
		echo "#                                                                               #"
	fi
	echo "#################################################################################"
	echo -e "${reset}"
	echo ""
}

function control_plane_showhelp {
	echo ""
	echo "#################################################################################################################"
	echo "#                                                                                                               #"
	echo "#                                                                                                               #"
	echo "#   This file contains the logic to prepare an Azure region to support the SAP Deployment Automation by         #"
	echo "#    preparing the deployer and the library.                                                                    #"
	echo "#   The script experts the following exports:                                                                   #"
	echo "#                                                                                                               #"
	echo "#     ARM_SUBSCRIPTION_ID to specify which subscription to deploy to                                            #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                                      #"
	echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                                     #"
	echo "#                                                                                                               #"
	echo "#   The script is to be run from a parent folder to the folders containing the json parameter files for         #"
	echo "#    the deployer and the library and the environment.                                                          #"
	echo "#                                                                                                               #"
	echo "#   The script will persist the parameters needed between the executions in the                                 #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                                         #"
	echo "#                                                                                                               #"
	echo "#                                                                                                               #"
	echo "#   Usage: deploy_controlplane.sh                                                                               #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                                            #"
	echo "#      -l or --library_parameter_file        library parameter file                                             #"
	echo "#                                                                                                               #"
	echo "#   Optional parameters                                                                                         #"
	echo "#      -s or --subscription                  subscription                                                       #"
	echo "#      -c or --spn_id                        SPN application id                                                 #"
	echo "#      -p or --spn_secret                    SPN password                                                       #"
	echo "#      -t or --tenant_id                     SPN Tenant id                                                      #"
	echo "#      -f or --force                         Clean up the local Terraform files.                                #"
	echo "#      -i or --auto-approve                  Silent install                                                     #"
	echo "#      -h or --help                          Help                                                               #"
	echo "#                                                                                                               #"
	echo "#   Example:                                                                                                    #"
	echo "#                                                                                                               #"
	echo "#  \$SAP_AUTOMATION_REPO_PATH/scripts/deploy_controlplane.sh \                                                   #"
	echo "#      --deployer_parameter_file DEPLOYER/MGMT-WEEU-DEP00-INFRASTRUCTURE/MGMT-WEEU-DEP00-INFRASTRUCTURE.json \  #"
	echo "#      --library_parameter_file LIBRARY/MGMT-WEEU-SAP_LIBRARY/MGMT-WEEU-SAP_LIBRARY.json \                      #"
	echo "#                                                                                                               #"
	echo "#   Example:                                                                                                    #"
	echo "#                                                                                                               #"
	echo "#   \$SAP_AUTOMATION_REPO_PATH/scripts/deploy_controlplane.sh \                                                  #"
	echo "#      --deployer_parameter_file DEPLOYER/PROD-WEEU-DEP00-INFRASTRUCTURE/PROD-WEEU-DEP00-INFRASTRUCTURE.json  \ #"
	echo "#      --library_parameter_file LIBRARY/PROD-WEEU-SAP_LIBRARY/PROD-WEEU-SAP_LIBRARY.json \                      #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                                    #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                                          #"
	echo "#      --spn_secret ************************ \                                                                  #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                                       #"
	echo "#      --auto-approve                                                                                           #"
	echo "#                                                                                                               #"
	echo "#################################################################################################################"
}

function control_plane_missing {
	printf -v val '%-40s' "$1"
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing : ${val}                                  #"
	echo "#                                                                                       #"
	echo "#   Usage: deploy_controlplane.sh                                                       #"
	echo "#      -d or --deployer_parameter_file       deployer parameter file                    #"
	echo "#      -l or --library_parameter_file        library parameter file                     #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#      -s or --subscription                  subscription                               #"
	echo "#      -c or --spn_id                        SPN application id                         #"
	echo "#      -p or --spn_secret                    SPN password                               #"
	echo "#      -t or --tenant_id                     SPN Tenant id                              #"
	echo "#      -f or --force                         Clean up the local Terraform files.        #"
	echo "#      -i or --auto-approve                  Silent install                             #"
	echo "#      -h or --help                          Help                                       #"
	echo "#                                                                                       #"
	echo "#########################################################################################"

}

function workload_zone_showhelp {
	echo ""
	echo "###############################################################################################"
	echo "#                                                                                             #"
	echo "#                                                                                             #"
	echo "#   This file contains the logic to deploy the workload infrastructure to Azure               #"
	echo "#                                                                                             #"
	echo "#   The script experts the following exports:                                                 #"
	echo "#                                                                                             #"
	echo "#   SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                       #"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                      #"
	echo "#                                                                                             #"
	echo "#   The script is to be run from the folder containing the json parameter file                #"
	echo "#                                                                                             #"
	echo "#   The script will persist the parameters needed between the executions in the               #"
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                       #"
	echo "#                                                                                             #"
	echo "#   Usage: install_workloadzone.sh                                                            #"
	echo "#      -p or --parameterfile                deployer parameter file                           #"
	echo "#                                                                                             #"
	echo "#   Optional parameters                                                                       #"
	echo "#      -d or --deployer_tfstate_key          Deployer terraform state file name               #"
	echo "#      -e or --deployer_environment          Deployer environment, i.e. MGMT                  #"
	echo "#      -s or --subscription                  subscription                                     #"
	echo "#      -k or --state_subscription            subscription for statefile                       #"
	echo "#      -c or --spn_id                        SPN application id                               #"
	echo "#      -p or --spn_secret                    SPN password                                     #"
	echo "#      -t or --tenant_id                     SPN Tenant id                                    #"
	echo "#      -f or --force                         Clean up the local Terraform files.              #"
	echo "#      -i or --auto-approve                  Silent install                                   #"
	echo "#      -h or --help                          Help                                             #"
	echo "#                                                                                             #"
	echo "#   Example:                                                                                  #"
	echo "#                                                                                             #"
	echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                       #"
	echo "#      --parameterfile PROD-WEEU-SAP01-INFRASTRUCTURE                                         #"
	echo "#                                                                                             #"
	echo "#   Example:                                                                                  #"
	echo "#                                                                                             #"
	echo "#   [REPO-ROOT]deploy/scripts/install_workloadzone.sh \                                       #"
	echo "#      --parameterfile PROD-WEEU-SAP01-INFRASTRUCTURE \                                       #"
	echo "#      --deployer_environment MGMT \                                                          #"
	echo "#      --subscription xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx \                                  #"
	echo "#      --spn_id yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                        #"
	echo "#      --spn_secret ************************ \                                                #"
	echo "#      --spn_secret yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy \                                    #"
	echo "#      --tenant_id zzzzzzzz-zzzz-zzzz-zzzz-zzzzzzzzzzzz \                                     #"
	echo "#      --auto-approve                                                                         #"
	echo "##############################################################################################"
}

function workload_zone_missing {
	printf -v val %-.40s "$1"
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables: ${val}!!!              #"
	echo "#                                                                                       #"
	echo "#   Please export the folloing variables:                                               #"
	echo "#   SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))                 #"
	echo "#   CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)                #"
	echo "#                                                                                       #"
	echo "#   Usage: install_workloadzone.sh                                                      #"
	echo "#      -p or --parameterfile                deployer parameter file                     #"
	echo "#                                                                                       #"
	echo "#   Optional parameters                                                                 #"
	echo "#      -d or --deployer_tfstate_key          Deployer terraform state file name         #"
	echo "#      -e or --deployer_environment          Deployer environment, i.e. MGMT            #"
	echo "#      -k or --state_subscription            subscription of keyvault with SPN details  #"
	echo "#      -v or --keyvault                      Name of Azure keyvault with SPN details    #"
	echo "#      -s or --subscription                  subscription                               #"
	echo "#      -c or --spn_id                        SPN application id                         #"
	echo "#      -o or --storageaccountname            Storage account for terraform state files  #"
	echo "#      -n or --spn_secret                    SPN password                               #"
	echo "#      -t or --tenant_id                     SPN Tenant id                              #"
	echo "#      -f or --force                         Clean up the local Terraform files.        #"
	echo "#      -i or --auto-approve                  Silent install                             #"
	echo "#      -h or --help                          Help                                       #"
	echo "#########################################################################################"
}

function validate_exports {
	if [ -z "$SAP_AUTOMATION_REPO_PATH" ]; then
		echo ""
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#  $bold_red Missing environment variables (SAP_AUTOMATION_REPO_PATH)!!! $reset_formatting                            #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables:                                              #"
		echo "#      SAP_AUTOMATION_REPO_PATH (path to the automation repo folder (sap-automation))   #"
		echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
		echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	if [ -z "$CONFIG_REPO_PATH" ]; then
		echo ""
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#  $bold_red Missing environment variables (CONFIG_REPO_PATH)!!! $reset_formatting                            #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables:                                              #"
		echo "#      CONFIG_REPO_PATH (path to the repo folder (sap-automation))                      #"
		echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
		echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#  $bold_red Missing environment variables (ARM_SUBSCRIPTION_ID)!!! $reset_formatting  #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables:                                              #"
		echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
		echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
		echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config))            #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	return 0
}

function validate_webapp_exports {
	if [ -z "$TF_VAR_app_registration_app_id" ]; then
		echo ""
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#        $bold_red Missing environment variables (TF_VAR_app_registration_app_id)!!! $reset_formatting            #"
		echo "#                                                                                       #"
		echo "#   Please export the following variables to successfully deploy the Webapp:            #"
		echo "#      TF_VAR_app_registration_app_id (webapp registration application id)              #"
		echo "#      TF_VAR_webapp_client_secret (webapp registration password / secret)              #"
		echo "#                                                                                       #"
		echo "#   If you do not wish to deploy the Webapp, unset the TF_VAR_use_webapp variable       #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		return 65 #data format error
	fi

	if [ "${ARM_USE_MSI}" == "false" ]; then
		if [ -z "$TF_VAR_webapp_client_secret" ]; then
			echo ""
			echo "#########################################################################################"
			echo "#                                                                                       #"
			echo -e "#            $bold_red Missing environment variables (TF_VAR_webapp_client_secret)!!! $reset_formatting           #"
			echo "#                                                                                       #"
			echo "#   Please export the following variables to successfully deploy the Webapp:            #"
			echo "#      TF_VAR_app_registration_app_id (webapp registration application id)              #"
			echo "#      TF_VAR_webapp_client_secret (webapp registration password / secret)              #"
			echo "#                                                                                       #"
			echo "#   If you do not wish to deploy the Webapp, unset the TF_VAR_use_webapp variable       #"
			echo "#                                                                                       #"
			echo "#########################################################################################"
			return 65 #data format error
		fi
	fi

	return 0
}

function showhelp {
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
	echo "#   [CONFIG_REPO_PATH]/.sap_deployment_automation folder                                                 #"
	echo "#                                                                                       #"
	echo "#                                                                                       #"
	echo "#   Usage: installer.sh                                                                 #"
	echo "#    -p or --parameterfile           parameter file                                     #"
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
	echo "#    -s or --state_subscription      Subscription for tfstate storage account           #"
	echo "#    -i or --auto-approve            Silent install                                     #"
	echo "#    -h or --help                    Show help                                          #"
	echo "#                                                                                       #"
	echo "#   Example:                                                                            #"
	echo "#                                                                                       #"
	echo "#   [REPO-ROOT]deploy/scripts/installer.sh \                                            #"
	echo "#      --parameterfile DEV-WEEU-SAP01-X00 \                                             #"
	echo "#      --type sap_system                                                                #"
	echo "#      --auto-approve                                                                   #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

function missing {
	printf -v val %-.40s "$option"
	echo ""
	echo ""
	echo "#########################################################################################"
	echo "#                                                                                       #"
	echo "#   Missing environment variables: ${option}!!!              #"
	echo "#                                                                                       #"
	echo "#   Please export the folloing variables:                                               #"
	echo "#      SAP_AUTOMATION_REPO_PATH (path to the repo folder (sap-automation))              #"
	echo "#      CONFIG_REPO_PATH (path to the configuration repo folder (sap-config)             #"
	echo "#      ARM_SUBSCRIPTION_ID (subscription containing the state file storage account)     #"
	echo "#      REMOTE_STATE_RG (resource group name for storage account containing state files) #"
	echo "#      REMOTE_STATE_SA (storage account for state file)                                 #"
	echo "#                                                                                       #"
	echo "#########################################################################################"
}

function validate_dependencies {
	tfPath="/opt/terraform/bin/terraform"

	if [ -f /opt/terraform/bin/terraform ]; then
		tfPath="/opt/terraform/bin/terraform"
	else
		tfPath=$(which terraform)
	fi

	echo "Checking Terraform:                  $tfPath"

	# if /opt/terraform exists, assign permissions to the user
	if [ -d /opt/terraform ]; then
		sudo chown -R "$USER" /opt/terraform
	fi

	# Check terraform
	if checkIfCloudShell; then
		tf=$(terraform --version | grep Terraform)
	else
		tf=$($tfPath --version | grep Terraform)
	fi

	if [ -z "$tf" ]; then
		print_banner "Installer" "Terraform not found" "error"
		return 2 #No such file or directory
	fi

	if checkIfCloudShell; then
		mkdir -p "${HOME}/.terraform.d/plugin-cache"
		export TF_PLUGIN_CACHE_DIR="${HOME}/.terraform.d/plugin-cache"
	else
		if [ ! -d "/opt/terraform/.terraform.d/plugin-cache" ]; then
			mkdir -p "/opt/terraform/.terraform.d/plugin-cache"
		fi
		export TF_PLUGIN_CACHE_DIR=/opt/terraform/.terraform.d/plugin-cache
	fi
	# Set Terraform Plug in cache

	az_version=$(az --version | grep "azure-cli")
	if [ -z "${az_version}" ]; then
		print_banner "Installer" "Azure CLI not found" "error"
		return 2 #No such file or directory
	fi
	cloudIDUsed=$(az account show | grep "cloudShellID" || true)
	if [ -n "${cloudIDUsed}" ]; then
		print_banner "Installer" "Please login using your credentials or service principal credentials" "error"
		exit 67 #addressee unknown
	fi

	return 0
}

function validate_key_parameters {
	echo "Validating:                          $1"

	# Helper variables
	load_config_vars "$1" "environment"
	environment=$(echo "${environment}" | xargs | tr "[:lower:]" "[:upper:]" | tr -d '\r')
	export environment

	if [ -z "${environment}" ]; then
		print_banner "Installer" "Incorrect parameter file" "error" "The file must contain the environment attribute"
		return 64 #script usage wrong
	fi

	load_config_vars "$1" "location"
	region=$(echo "${location}" | xargs | tr -d '\r')
	export region

	if [ -z "${region}" ]; then
		print_banner "Installer" "Incorrect parameter file" "error" "The file must contain the location attribute"
		return 64 #script usage wrong
	fi

	load_config_vars "$1" "management_network_logical_name"
	export management_network_logical_name

	load_config_vars "$1" "network_logical_name"
	export network_logical_name

	return 0
}

function version_compare {
	echo "Comparison:                          $1 <= $2"

	if [ -z $1 ]; then
		return 2
	fi

	if [[ "$1" == "$2" ]]; then
		return 0
	fi
	local IFS=.
	local i ver1=($1) ver2=($2)
	# fill empty fields in ver1 with zeros
	for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
		ver1[i]=0
	done
	for ((i = 0; i < ${#ver1[@]}; i++)); do
		if ((10#${ver1[i]:=0} > 10#${ver2[i]:=0})); then
			return 1
		fi
		if ((10#${ver1[i]} < 10#${ver2[i]})); then
			return 2
		fi
	done
	return 0
}

function ReplaceResourceInStateFile {

	local moduleID=$1
	local terraform_module_directory=$2

	# shellcheck disable=SC2086
	if [ -z $STORAGE_ACCOUNT_ID ]; then
		azureResourceID=$(terraform -chdir="${terraform_module_directory}" state show "${moduleID}" | grep -m1 $3 | xargs | cut -d "=" -f2 | xargs)
		tempString=$(echo "${azureResourceID}" | grep "/fileshares/")
		if [ -n "${tempString}" ]; then
			# Use sed to replace /fileshares/ with /shares/
			# shellcheck disable=SC2001
			azureResourceID=$(echo "$azureResourceID" | sed 's|/fileshares/|/shares/|g')
		fi
	else
		azureResourceID=$STORAGE_ACCOUNT_ID
	fi

	echo "Terraform resource ID:  $moduleID"
	echo "Azure resource ID:      $azureResourceID"
	if [ -n "${azureResourceID}" ]; then
		echo "Removing storage account state object:           ${moduleID} "
		if terraform -chdir="${terraform_module_directory}" state rm "${moduleID}"; then
			echo "Importing storage account state object:           ${moduleID}"
			echo "terraform -chdir=${terraform_module_directory} import -var-file=${var_file} -var deployer_tfstate_key=${deployer_tfstate_key} -var tfstate_resource_id=${tfstate_resource_id} $4 ${moduleID} ${azureResourceID}"
			if ! terraform -chdir="${terraform_module_directory}" import -var-file="${var_file}" -var "deployer_tfstate_key=${deployer_tfstate_key}" -var "tfstate_resource_id=${tfstate_resource_id}" $4 "${moduleID}" "${azureResourceID}"; then
				echo -e "$bold_red Importing storage account state object:           ${moduleID} failed $reset_formatting"
				exit 65
			fi
		fi
	fi

	return $?
}

function ImportAndReRunApply {
	local fileName=$1
	local terraform_module_directory=$2
	local importParameters=$3
	local applyParameters=$4

	import_return_value=0

	if [ -f "$fileName" ]; then

		errors_occurred=$(jq 'select(."@level" == "error") | length' "$fileName")

		if [[ -n $errors_occurred ]]; then
			print_banner "Installer" "Errors during the apply phase" "error"

			# Check for resource that can be imported
			existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary} | select(.summary | startswith("A resource with the ID"))' "$fileName")
			if [[ -n ${existing} ]]; then

				readarray -t existing_resources < <(echo ${existing} | jq -c '.')
				for item in "${existing_resources[@]}"; do
					moduleID=$(jq -c -r '.address ' <<<"$item")
					azureResourceID=$(jq -c -r '.summary' <<<"$item" | awk -F'\"' '{print $2}')
					echo "Trying to import $azureResourceID into $moduleID"
					# shellcheck disable=SC2086
					echo terraform -chdir="${terraform_module_directory}" import $importParameters "${moduleID}" "${azureResourceID}"
					# shellcheck disable=SC2086
					if ! terraform -chdir="${terraform_module_directory}" import $importParameters -no-color "${moduleID}" "${azureResourceID}" | tee -a import_result.txt; then
						import_return_value=${PIPESTATUS[0]}
						moduleName=$(grep "^module..*.." .import_result.txt | cut -d' ' -f1 | sed 's/.$//')
						echo "Removing state object:           ${moduleName}"
						if terraform -chdir="${terraform_module_directory}" state rm "${moduleName}"; then

							if ! terraform -chdir="${terraform_module_directory}" import $importParameters -no-color "${moduleID}" "${azureResourceID}"; then
								import_return_value=$?
							else
								import_return_value=0
							fi
						fi
					fi
				done
				# shellcheck disable=SC2086
				if ! terraform -chdir="${terraform_module_directory}" plan -input=false $allImportParameters; then
					print_banner "Installer" "Terraform plan failed" "error"
				fi

				print_banner "Installer" "Re-running Terraform apply after import" "info"

				# shellcheck disable=SC2086
				if terraform -chdir="${terraform_module_directory}" apply -no-color -compact-warnings -json -input=false --auto-approve $applyParameters | tee -a "$fileName"; then
					import_return_value=${PIPESTATUS[0]}
				else
					import_return_value=${PIPESTATUS[0]}
				fi
				if [ $import_return_value -eq 1 ]; then
					print_banner "Installer" "Errors during the apply phase after importing resources" "error"
				else
					# return code 2 is ok
					print_banner "Installer" "Terraform apply succeeded" "success"
					if [ -f "$fileName" ]; then
						rm "$fileName"
					fi
					import_return_value=0
				fi
			else
				print_banner "Installer" "Terraform apply failed" "error"
			fi
			errors_occurred=$(jq 'select(."@level" == "error") | length' "$fileName")
			if [[ -n $errors_occurred ]]; then
				existing=$(jq 'select(."@level" == "error") | {address: .diagnostic.address, summary: .diagnostic.summary} | select(.summary | startswith("A resource with the ID"))' "$fileName")
				if [[ -n ${existing} ]]; then
					import_return_value=0

				fi
			fi
		else
			print_banner "Installer" "No resources to import" "info"
			import_return_value=10
		fi

	fi

	return $import_return_value
}

function testIfResourceWouldBeRecreated {
	local moduleId="$1"
	local fileName="$2"
	local shortName="$3"
	printf -v val '%-40s' "$shortName"
	return_value=0
	# || true suppresses the exitcode of grep. To not trigger the strict exit on error
	willResourceWouldBeRecreated=$(grep "$moduleId" "$fileName" | grep -m1 "must be replaced" || true)
	if [ -n "${willResourceWouldBeRecreated}" ]; then
		print_banner "Installer" "Risk for dataloss" "error" "${val} will be removed"
		echo "##vso[task.logissue type=error]Resource will be removed: $shortName"
		return_value=1
	fi
	return $return_value
}

function validate_key_vault {
	local keyvault_to_check=$1
	local subscription=$2
	return_value=0

	kv_name_check=$(az keyvault show --name="$keyvault_to_check" --subscription "${subscription}" --query name)
	return_value=$?
	if [ -z "$kv_name_check" ]; then
		echo ""
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                             $cyan  Retrying keyvault access $reset_formatting                               #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		sleep 60
		kv_name_check=$(az keyvault show --name="$keyvault_to_check" --subscription "${subscription}" --query name)
		return_value=$?
	fi

	if [ -z "$kv_name_check" ]; then
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#                               $bold_red  Unable to access keyvault: $keyvault_to_check $reset_formatting                            #"
		echo "#                             Please ensure the key vault exists.                       #"
		echo "#                                                                                       #"
		echo "#########################################################################################"
		echo ""
		exit 10
	fi

	access_error=$(az keyvault secret list --vault "$keyvault_to_check" --subscription "${subscription}" --only-show-errors | grep "The user, group or application" || true)
	if [ -n "${access_error}" ]; then

		az_subscription_id=$(az account show --query id -o tsv)
		printf -v val %-40.40s "$az_subscription_id"
		echo "#########################################################################################"
		echo "#                                                                                       #"
		echo -e "#$bold_red User account ${val} does not have access to: $keyvault  $reset_formatting"
		echo "#                                                                                       #"
		echo "#########################################################################################"

		echo "##vso[task.setprogress value=40;]Progress Indicator"
		return 65

	fi
	return $return_value

}

function LogonToAzure() {
	local useMSI=$1
	local subscriptionId=$ARM_SUBSCRIPTION_ID

	if [ "$useMSI" != "true" ]; then
		echo "Deployment credentials:              Service Principal"
		echo "Deployment credential ID (SPN):      $ARM_CLIENT_ID"
		unset ARM_USE_MSI
		az login --service-principal --username "$ARM_CLIENT_ID" --password="$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" --output none
		echo "Logged on as:"
		az account show --query user --output yaml
		TF_VAR_use_spn=true
		export TF_VAR_use_spn

	else
		echo "Deployment credentials:              Managed Service Identity"
		source "/etc/profile.d/deploy_server.sh"
		TF_VAR_use_spn=false
		export TF_VAR_use_spn

		# sourcing deploy_server.sh overwrites ARM_SUBSCRIPTION_ID with control plane subscription id
		# ensure we are exporting the right ARM_SUBSCRIPTION_ID when authenticating against workload zones.
		if [[ "$ARM_SUBSCRIPTION_ID" != "$subscriptionId" ]]; then
			ARM_SUBSCRIPTION_ID=$subscriptionId
			export ARM_SUBSCRIPTION_ID
		fi
	fi

}

#!/bin/bash
green="\e[1;32m"
reset="\e[0m"
boldred="\e[1;31m"
cyan="\e[1;36m"

#External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"

debug=False

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  set -o errexit
  debug=True
  export debug
fi
set -eu

echo "##vso[build.updatebuildnumber]Deploying the SAP System defined in $(sap_system_folder)"

tfvarsFile="SYSTEM/$(sap_system_folder)/$(sap_system_configuration)"

echo -e "$green--- Checkout $BRANCH ---$reset"

cd "${CONFIG_REPO_PATH}" || exit
mkdir -p .sap_deployment_automation
git checkout -q "$BRANCH"

if [ ! -f "$CONFIG_REPO_PATH/SYSTEM/$(sap_system_folder)/$(sap_system_configuration)" ]; then
  echo -e "$boldred--- $(sap_system_configuration) was not found ---$reset"
  echo "##vso[task.logissue type=error]File $(sap_system_configuration) was not found."
  exit 2
fi

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

  if [ -z "$WL_ARM_SUBSCRIPTION_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_SUBSCRIPTION_ID" == '$$(ARM_SUBSCRIPTION_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$WL_ARM_CLIENT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_CLIENT_ID" == '$$(ARM_CLIENT_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$WL_ARM_CLIENT_SECRET" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_CLIENT_SECRET" == '$$(ARM_CLIENT_SECRET)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$WL_ARM_TENANT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$WL_ARM_TENANT_ID" == '$$(ARM_TENANT_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_TENANT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$CP_ARM_SUBSCRIPTION_ID" ]; then
    echo "##vso[task.logissue type=error]Variable CP_ARM_SUBSCRIPTION_ID was not defined in the $(parent_variable_group) variable group."
    exit 2
  fi
fi

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
  configureNonDeployer "$(tf_version)" || true
  echo -e "$green--- az login ---$reset"
  LogonToAzure false || true
else
  LogonToAzure "$USE_MSI" || true
fi
return_code=$?
if [ 0 != $return_code ]; then
  echo -e "$boldred--- Login failed ---$reset"
  echo "##vso[task.logissue type=error]az login failed."
  exit $return_code
fi

ARM_SUBSCRIPTION_ID=$WL_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID
az account set --subscription "$ARM_SUBSCRIPTION_ID"

echo -e "$green--- Read deployment details ---$reset"
dos2unix -q tfvarsFile

ENVIRONMENT=$(grep -m1 "^environment" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$tfvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')
NETWORK=$(grep -m1 "^network_logical_name" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
SID=$(grep -m1 "^sid" "$tfvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')

ENVIRONMENT_IN_FILENAME=$(echo $(sap_system_folder) | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo $(sap_system_folder) | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

NETWORK_IN_FILENAME=$(echo $(sap_system_folder) | awk -F'-' '{print $3}')

SID_IN_FILENAME=$(echo $(sap_system_folder) | awk -F'-' '{print $4}')

echo "System TFvars:                       $(sap_system_configuration)"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"
echo "Network:                             $NETWORK"
echo "SID:                                 $SID"

echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo "Network(filename):                   $NETWORK_IN_FILENAME"
echo "SID(filename):                       $SID_IN_FILENAME"

echo ""

echo "Agent pool:                          $(this_agent)"
echo "Organization:                        $ENDPOINT_URL_SYSTEMVSSCONNECTION"
echo "Project:                             $SYSTEM_TEAMPROJECT"
echo ""
echo "Azure CLI version:"
echo "-------------------------------------------------"
az --version

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The environment setting in $(sap_system_configuration) '$ENVIRONMENT' does not match the $(sap_system_configuration) file name '$ENVIRONMENT_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The location setting in $(sap_system_configuration) '$LOCATION' does not match the $(sap_system_configuration) file name '$LOCATION_IN_FILENAME'. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$NETWORK" != "$NETWORK_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The network_logical_name setting in $(sap_system_configuration) '$NETWORK' does not match the $(sap_system_configuration) file name '$NETWORK_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$SID" != "$SID_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The sid setting in $(sap_system_configuration) '$SID' does not match the $(sap_system_configuration) file name '$SID_IN_FILENAME-. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-[SID]"
  exit 2
fi

workload_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION_CODE_IN_FILENAME}${NETWORK}"
echo "Workload Zone Environment File:      $workload_environment_file_name"

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --output none --only-show-errors

az extension add --name azure-devops --output none --only-show-errors

az devops configure --defaults organization=$ENDPOINT_URL_SYSTEMVSSCONNECTION project='$SYSTEM_TEAMPROJECT' --output none

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$(variable_group)'].id | [0]")

if [ -z "${VARIABLE_GROUP_ID}" ]; then
  echo "##vso[task.logissue type=error]Variable group $(variable_group) could not be found."
  exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$(variable_group)"
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
echo "Target subscription                  $WL_ARM_SUBSCRIPTION_ID"

echo "Terraform state file subscription:   $STATE_SUBSCRIPTION"
echo "Terraform state file storage account:$REMOTE_STATE_SA"

tfstate_resource_id=$(az resource list --name "${REMOTE_STATE_SA}" --subscription "$STATE_SUBSCRIPTION" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
export tfstate_resource_id

echo -e "$green--- Deploy the System ---$reset"
cd "$CONFIG_REPO_PATH/SYSTEM/$(sap_system_folder)" || exit

"$SAP_AUTOMATION_REPO_PATH/deploy/scripts/installer.sh" --parameterfile $(sap_system_configuration) --type sap_system \
  --state_subscription "${STATE_SUBSCRIPTION}" --storageaccountname "${REMOTE_STATE_SA}" \
  --deployer_tfstate_key "${deployer_tfstate_key}" --landscape_tfstate_key "${landscape_tfstate_key}" \
  --ado --auto-approve

return_code=$?
echo "Return code from deployment:         ${return_code}"
if [ 0 != $return_code ]; then
  echo "##vso[task.logissue type=error]Return code from installer $return_code."
fi

set +o errexit

echo -e "$green--- Add & update files in the DevOps Repository ---$reset"
cd "$(Build.Repository.LocalPath)" || exit
git pull

# Pull changes if there are other deployment jobs

cd "${CONFIG_REPO_PATH}/SYSTEM/$(sap_system_folder)" || exit

echo -e "$green--- Pull the latest content from DevOps ---$reset"
git pull
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
fi

if [ -f "${SID}_hosts.yaml" ]; then
  git add -f "${SID}_hosts.yaml"
  added=1
fi

if [ -f "${SID}.md" ]; then
  git add "${CONFIG_REPO_PATH}/SYSTEM/$(sap_system_folder)/${SID}.md"
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

if [ -f $(sap_system_configuration) ]; then
  git add $(sap_system_configuration)
  added=1
fi

if [ -f "${SID}_virtual_machines.json" ]; then
  git add "${SID}_virtual_machines.json"
  added=1
fi

if [ 1 == $added ]; then
  git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
  git config --global user.name "$BUILD_REQUESTEDFOR"
  git commit -m "Added updates from devops deployment $BUILD_BUILDNUMBER [skip ci]"

  if git -c http.extraheader="AUTHORIZATION: bearer SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BRANCH" --force; then
    echo "##vso[task.logissue type=warning]Changes pushed to $BRANCH"
  else
    echo "##vso[task.logissue type=error]Failed to push changes to $BRANCH"
  fi
fi

# file_name=${SID}_inventory.md
# if [ -f ${SID}_inventory.md ]; then
#   az devops configure --defaults organization=$ENDPOINT_URL_SYSTEMVSSCONNECTION project='$SYSTEM_TEAMPROJECT' --output none

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
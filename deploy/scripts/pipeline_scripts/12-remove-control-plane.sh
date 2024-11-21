#!/bin/bash

echo "##vso[build.updatebuildnumber]Removing the control plane defined in $DEPLOYERFOLDER $LIBRARYFOLDER"
green="\e[1;32m"
reset="\e[0m"
boldred="\e[1;31m"
cyan="\e[1;36m"

# External helper functions
#. "$(dirname "${BASH_SOURCE[0]}")/deploy_utils.sh"
full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"

#call stack has full scriptname when using source
source "${script_directory}/helper.sh"

debug=False

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  set -eu
  debug=True
  export debug
fi
# Ensure that the exit status of a pipeline command is non-zero if any
# stage of the pipefile has a non-zero exit status.
set -o pipefail

deployer_environment_file_name="${CONFIG_REPO_PATH}/.sap_deployment_automation/${ENVIRONMENT}$LOCATION"
deployerTFvarsFile="${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER/$DEPLOYERCONFIG"
libraryTFvarsFile="${CONFIG_REPO_PATH}/LIBRARY/$LIBRARYFOLDER/$LIBRARYCONFIG"
deployer_tfstate_key="$DEPLOYERFOLDER.terraform.tfstate"

echo -e "$green--- File Validations ---$reset"

if [ ! -f "$deployerTFvarsFile" ]; then
  echo -e "$boldred--- File ${deployerTFvarsFile} was not found ---$reset"
  echo "##vso[task.logissue type=error]File DEPLOYER/$DEPLOYERFOLDER/$DEPLOYERCONFIG was not found."
  exit 2
fi

if [ ! -f "${libraryTFvarsFile}" ]; then
  echo -e "$boldred--- File "${libraryTFvarsFile}"  was not found ---$reset"
  echo "##vso[task.logissue type=error]File LIBRARY/$LIBRARYFOLDER/$LIBRARYCONFIG was not found."
  exit 2
fi

TF_VAR_deployer_tfstate_key="$deployer_tfstate_key"
export TF_VAR_deployer_tfstate_key

echo -e "$green--- Environment information ---$reset"
ENVIRONMENT=$(grep -m1 "^environment" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"')
LOCATION=$(grep -m1 "^location" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"')

# shellcheck disable=SC2005
ENVIRONMENT_IN_FILENAME=$(echo $DEPLOYERFOLDER | awk -F'-' '{print $1}')

LOCATION_CODE_IN_FILENAME=$(echo $DEPLOYERFOLDER | awk -F'-' '{print $2}')
LOCATION_IN_FILENAME=$(get_region_from_code "$LOCATION_CODE_IN_FILENAME" || true)

echo "Environment:                         ${ENVIRONMENT}"
echo "Location:                            ${LOCATION}"
echo "Environment(filename):               $ENVIRONMENT_IN_FILENAME"
echo "Location(filename):                  $LOCATION_IN_FILENAME"
echo ""
echo "Agent:                               $THIS_AGENT"
echo "Organization:                        $ENDPOINT_URL_SYSTEMVSSCONNECTION"
echo "Project:                             $SYSTEM_TEAMPROJECT"
if [ -n "$TF_VAR_agent_pat" ]; then
  echo "Deployer Agent PAT:                  IsDefined"
fi
if [ -n "$POOL" ]; then
  echo "Deployer Agent Pool:                 $POOL"
fi

if [ "$ENVIRONMENT" != "$ENVIRONMENT_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The environment setting in $deployerTFvarsFile $ENVIRONMENT does not match the $DEPLOYERFOLDER file name $ENVIRONMENT_IN_FILENAME. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

if [ "$LOCATION" != "$LOCATION_IN_FILENAME" ]; then
  echo "##vso[task.logissue type=error]The location setting in $deployerTFvarsFile $LOCATION does not match the $DEPLOYERFOLDER file name $LOCATION_IN_FILENAME. Filename should have the pattern [ENVIRONMENT]-[REGION_CODE]-[NETWORK_LOGICAL_NAME]-INFRASTRUCTURE"
  exit 2
fi

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/$ENVIRONMENT$LOCATION_CODE_IN_FILENAME"
echo "Environment file:                    $deployer_environment_file_name"

REMOTE_STATE_SA=""
REMOTE_STATE_RG=$LIBRARYFOLDER
sourced_from_file=0

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

if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
  echo "##vso[task.logissue type=error]Variable ARM_SUBSCRIPTION_ID was not defined."
  exit 2
fi

echo -e "$green--- Validations ---$reset"
if [ "$USE_MSI" != "true" ]; then

  if [ -z "$CP_ARM_CLIENT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable CP_ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$CP_ARM_CLIENT_ID" == '$$(CP_ARM_CLIENT_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$CP_ARM_CLIENT_SECRET" ]; then
    echo "##vso[task.logissue type=error]Variable CP_ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$CP_ARM_CLIENT_SECRET" == '$$(CP_ARM_CLIENT_SECRET)' ]; then
    echo "##vso[task.logissue type=error]Variable ARM_CLIENT_SECRET was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ -z "$CP_ARM_TENANT_ID" ]; then
    echo "##vso[task.logissue type=error]Variable CP_ARM_TENANT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

  if [ "$CP_WL_ARM_TENANT_ID" == '$$(CP_ARM_TENANT_ID)' ]; then
    echo "##vso[task.logissue type=error]Variable CP_ARM_TENANT_ID was not defined in the $(variable_group) variable group."
    exit 2
  fi

fi

# Set logon variables
ARM_CLIENT_ID="$CP_ARM_CLIENT_ID"
export ARM_CLIENT_ID
ARM_CLIENT_SECRET="$CP_ARM_CLIENT_SECRET"
export ARM_CLIENT_SECRET
ARM_TENANT_ID=$CP_ARM_TENANT_ID
export ARM_TENANT_ID
ARM_SUBSCRIPTION_ID=$CP_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID

# Check if running on deployer
if [[ ! -f /etc/profile.d/deploy_server.sh ]]; then
  configureNonDeployer "$TF_VERSION" || true
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

ARM_SUBSCRIPTION_ID=$CP_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID
az account set --subscription "$ARM_SUBSCRIPTION_ID"

key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault" || true)
export key_vault

STATE_SUBSCRIPTION=$ARM_SUBSCRIPTION_ID
export STATE_SUBSCRIPTION

REMOTE_STATE_SA=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Account_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA" || true)
export REMOTE_STATE_SA

REMOTE_STATE_RG=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Terraform_Remote_Storage_Resource_Group_Name" "${deployer_environment_file_name}" "REMOTE_STATE_SA" || true)
export REMOTE_STATE_RG

echo "Terraform state subscription:        $STATE_SUBSCRIPTION"
echo "Terraform state rg name:             $REMOTE_STATE_RG"
echo "Terraform state account:             $REMOTE_STATE_SA"
echo "Deployer Key Vault:                  ${key_vault}"

if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/state.zip" ]; then
  pass=${SYSTEM_COLLECTIONID//-/}
  unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/state.zip" -d "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)"
fi

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER/state.zip" ]; then
  pass=${SYSTEM_COLLECTIONID//-/}
  unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER"
fi

echo -e "$green--- Running the remove region script that destroys deployer VM and SAP library ---$reset"

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_controlplane.sh" \
  --deployer_parameter_file "$deployerTFvarsFile" \
  --library_parameter_file "$libraryTFvarsFile" \
  --storage_account "$REMOTE_STATE_SA" \
  --subscription "${STATE_SUBSCRIPTION}" \
  --resource_group "$REMOTE_STATE_RG" \
  --ado --auto-approve --keep_agent; then
  echo "Control Plane $DEPLOYERFOLDER removal step 1 completed."
  echo "##vso[task.logissue type=warning]Control Plane $DEPLOYERFOLDER removal step 1 completed."
else
  return_code=$?
  echo "Control Plane $DEPLOYERFOLDER removal step 1 failed."
fi
return_code=$?

echo "Return code from remove_controlplane: $return_code."

echo -e "$green--- Remove Control Plane Part 1 ---$reset"
cd "$CONFIG_REPO_PATH" || exit
git checkout -q "$(Build.SourceBranchName)"

changed=0
if [ -f "$deployer_environment_file_name" ]; then
  git add "$deployer_environment_file_name"
  changed=1
fi

if [ -f "DEPLOYER/$DEPLOYERFOLDER/terraform.tfstate" ]; then
  echo "Compressing the state file."
  sudo apt-get -qq install zip
  pass=${SYSTEM_COLLECTIONID//-/}

  zip -q -j -P "${pass}" "DEPLOYER/$DEPLOYERFOLDER/state DEPLOYER/$DEPLOYERFOLDER/terraform.tfstate"
  git add -f "DEPLOYER/$DEPLOYERFOLDER/state.zip"
  changed=1
fi
if [ $return_code != 0 ]; then
  backend=$(grep "local" "LIBRARY/$(library_folder)/.terraform/terraform.tfstate" || true)
  if [ -n "${backend}" ]; then
    echo "Local Terraform state"
    if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/terraform.tfstate" ]; then
      sudo apt-get -qq install zip
      echo "Compressing the library state file"
      pass=${SYSTEM_COLLECTIONID//-/}
      zip -q -j -P "${pass}" "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/state" "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/terraform.tfstate"
      git add -f "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/state.zip"
      changed=1
    fi
  else
    echo "Remote Terraform state"
    if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/terraform.tfstate" ]; then
      git rm -q -f --ignore-unmatch "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/terraform.tfstate"
      changed=1
    fi
    if [ -f "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/state.zip" ]; then
      git rm -q --ignore-unmatch -f "${CONFIG_REPO_PATH}/LIBRARY/$(library_folder)/state.zip"
      changed=1
    fi
  fi
else
  if [ -d "LIBRARY/$(library_folder)/.terraform" ]; then
    git rm -q -r --ignore-unmatch "LIBRARY/$(library_folder)/.terraform"
    changed=1
  fi

  if [ -f "LIBRARY/$(library_folder)/state.zip" ]; then
    git rm -q --ignore-unmatch "LIBRARY/$(library_folder)/state.zip"
    changed=1
  fi

  if [ -f "LIBRARY/$(library_folder)/backend-config.tfvars" ]; then
    git rm -q --ignore-unmatch "LIBRARY/$(library_folder)/backend-config.tfvars"
    changed=1
  fi
fi

if [ -f "DEPLOYER/$DEPLOYERFOLDER/.terraform/terraform.tfstate" ]; then
  git add -f "DEPLOYER/$DEPLOYERFOLDER/.terraform/terraform.tfstate"
  changed=1
fi

if [ 1 == $changed ]; then
  git config --global user.email "$(Build.RequestedForEmail)"
  git config --global user.name "$(Build.RequestedFor)"
  git commit -m "Control Plane $DEPLOYERFOLDER removal step 1[skip ci]"

  if git -c http.extraheader="AUTHORIZATION: bearer $(System.AccessToken)" push --set-upstream origin "$(Build.SourceBranchName)" --force; then
    return_code=$?
    echo "##vso[task.logissue type=warning]Control Plane $DEPLOYERFOLDER removal step 1 updated in $(Build.SourceBranchName)"
  else
    return_code=$?
    echo "##vso[task.logissue type=error]Failed to push changes to $(Build.SourceBranchName)"
  fi

fi

exit $return_code

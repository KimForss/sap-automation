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
ENVIRONMENT=$(grep -m1 "^environment" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr -d ' \t\n\r\f"' || true)
LOCATION=$(grep -m1 "^location" "$deployerTFvarsFile" | awk -F'=' '{print $2}' | tr '[:upper:]' '[:lower:]' | tr -d ' \t\n\r\f"' || true)

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

echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors
az extension add --name azure-devops --output none --only-show-errors
az devops configure --defaults organization="$ENDPOINT_URL_SYSTEMVSSCONNECTION" project="$SYSTEM_TEAMPROJECT" --output none --only-show-errors

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

echo "Deployer Key Vault:                  $key_vault"

key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
if [ -n "${key_vault_id}" ]; then
  if [ "azure pipelines" = "$(this_agent)" ]; then
    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --only-show-errors --output none
  fi
fi

echo -e "$green--- Running the remove_deployer script that destroys deployer VM ---$reset"

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER/state.zip" ]; then
  pass=${SYSTEM_COLLECTIONID//-/}
  unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$DEPLOYERFOLDER"
fi

echo -e "$green--- Running the remove region script that destroys deployer VM and SAP library ---$reset"

cd "$CONFIG_REPO_PATH/DEPLOYER/$DEPLOYERFOLDER" || exit

if "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/remove_deployer.sh" --auto-approve \
  --parameterfile "$DEPLOYERCONFIG"; then
  echo "Control Plane $DEPLOYERFOLDER removal step 2 completed."
  echo "##vso[task.logissue type=warning]Control Plane $DEPLOYERFOLDER removal step 2 completed."
else
  return_code=$?
  echo "Control Plane $DEPLOYERFOLDER removal step 2 failed."
fi

return_code=$?

echo "Return code from remove_deployer: $return_code."

echo -e "$green--- Remove Control Plane Part 2 ---$reset"
cd "$CONFIG_REPO_PATH" || exit
git checkout -q "$BRANCH"
git pull -q

if [ 0 == $return_code ]; then
  cd "$CONFIG_REPO_PATH" || exit
  changed=0

  if [ -f "DEPLOYER/$DEPLOYERFOLDER/.terraform/terraform.tfstate" ]; then
    git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYERFOLDER/.terraform/terraform.tfstate"
    changed=1
  fi

  if [ -d "DEPLOYER/$DEPLOYERFOLDER/.terraform" ]; then
    git rm -q -r --ignore-unmatch "DEPLOYER/$DEPLOYERFOLDER/.terraform"
    changed=1
  fi

  if [ -f "DEPLOYER/$DEPLOYERFOLDER/state.zip" ]; then
    git rm -q -f --ignore-unmatch "DEPLOYER/$DEPLOYERFOLDER/state.zip"
    changed=1
  fi

  if [ -d "LIBRARY/$LIBRARYFOLDER/.terraform" ]; then
    git rm -q -r --ignore-unmatch "LIBRARY/$LIBRARYFOLDER/.terraform"
    changed=1
  fi

  if [ -f "LIBRARY/$LIBRARYFOLDER/state.zip" ]; then
    git rm -q -f --ignore-unmatch "LIBRARY/$LIBRARYFOLDER/state.zip"
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

  if [ -f "LIBRARY/$LIBRARYFOLDER/backend-config.tfvars" ]; then
    git rm -q --ignore-unmatch "LIBRARY/$LIBRARYFOLDER/backend-config.tfvars"
    changed=1
  fi

  if [ 1 == $changed ]; then
    git config --global user.email "$BUILD_REQUESTEDFOREMAIL"
    git config --global user.name "$BUILD_REQUESTEDFOR"
    git commit -m "Control Plane $DEPLOYERFOLDER removal step 2[skip ci]"
    if git -c http.extraheader="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN" push --set-upstream origin "$BRANCH" --force-with-lease; then
      return_code=$?
      echo "##vso[task.logissue type=warning]Control Plane $DEPLOYERFOLDER removal step 2 updated in $BRANCH"
    else
      return_code=$?
      echo "##vso[task.logissue type=error]Failed to push changes to $BRANCH"
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

    variable_value=$(az pipelines variable-group variable list --group-id "${VARIABLE_GROUP_ID}" --query "Deployer_Key_Vault.value")
    if [ ${#variable_value} != 0 ]; then
      az pipelines variable-group variable delete --group-id "${VARIABLE_GROUP_ID}" --name Deployer_Key_Vault --yes --only-show-errors
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

  fi

fi

exit $return_code

#!/bin/bash
echo "##vso[build.updatebuildnumber]Deploying the control plane defined in $deployer_folder $library_folder"
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

if [ "$SYSTEM_DEBUG" = True ]; then
  set -x
  debug=true
  export debug
fi
set -eu

file_deployer_tfstate_key=$deployer_folder.tfstate
deployer_tfstate_key="$deployer_folder.terraform.tfstate"

cd "$CONFIG_REPO_PATH" || exit
mkdir -p .sap_deployment_automation


ENVIRONMENT=$(echo "$deployer_folder" | awk -F'-' '{print $1}' | xargs)

LOCATION=$(echo "$deployer_folder" | awk -F'-' '{print $2}' | xargs)

deployer_environment_file_name="$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
echo "Configuration file:                  $deployer_environment_file_name"
echo "Environment:                         $ENVIRONMENT"
echo "Location:                            $LOCATION"

if [ -f "${deployer_environment_file_name}" ]; then
  step=$(grep -m1 "^step=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs)
  echo "Step:                                $step"
  if [ "0" != "${step}" ]; then
    echo "##vso[task.logissue type=warning]Already prepared"
    exit 0
  fi
fi

echo -e "$green--- Checkout $sourceBranchName ---$reset"
git checkout -q "$sourceBranchName"
echo -e "$green--- Configure devops CLI extension ---$reset"
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors

az extension add --name azure-devops --output none --only-show-errors

echo -e "$green--- File Validations ---$reset"
if [ ! -f "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/$deployer_config" ]; then
  echo -e "$boldred--- File ${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/$deployer_config was not found ---$reset"
  echo "##vso[task.logissue type=error]File ${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/$deployer_config was not found."
  exit 2
fi
if [ ! -f "${CONFIG_REPO_PATH}/LIBRARY/$library_folder/$library_config" ]; then
  echo -e "$boldred--- File ${CONFIG_REPO_PATH}/LIBRARY/$library_folder/$library_config  was not found ---$reset"
  echo "##vso[task.logissue type=error]File ${CONFIG_REPO_PATH}/LIBRARY/$library_folder/$library_config was not found."
  exit 2
fi

echo ""
echo "Agent:                               $(this_agent)"
echo "Organization:                        $(System.CollectionUri)"
echo "Project:                             $(System.TeamProject)"
if [ -n "$(PAT)" ]; then
  echo "Deployer Agent PAT:                  IsDefined"
fi
if [ -n "$(POOL)" ]; then
  echo "Deployer Agent Pool:                 $(POOL)"
fi
echo ""
if [ "$(use_webapp)" = "true" ]; then
  echo "Deploy Web App:                      true"

else
  echo "Deploy Web App:                      false"
fi

az devops configure --defaults organization="$(System.CollectionUri)" project='$(System.TeamProject)' --output none --only-show-errors

VARIABLE_GROUP_ID=$(az pipelines variable-group list --query "[?name=='$(variable_group)'].id | [0]")
if [ -z "${VARIABLE_GROUP_ID}" ]; then
  echo "##vso[task.logissue type=error]Variable group $(variable_group) could not be found."
  exit 2
fi
export VARIABLE_GROUP_ID

printf -v tempval '%s id:' "$(variable_group)"
printf -v val '%-20s' "${tempval}"
echo "$val                 $VARIABLE_GROUP_ID"

az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

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
  configureNonDeployer "$(tf_version)"

  ARM_CLIENT_ID="$servicePrincipalId"
  export ARM_CLIENT_ID

  ARM_OIDC_TOKEN="$idToken"
  export ARM_OIDC_TOKEN

  ARM_TENANT_ID="$tenantId"
  export ARM_TENANT_ID

  ARM_USE_OIDC=true
  export ARM_USE_OIDC

  ARM_USE_AZUREAD=true
  export ARM_USE_AZUREAD

  unset ARM_CLIENT_SECRET

else
  echo -e "$green--- az login ---$reset"
  LogonToAzure "$USE_MSI"
fi
return_code=$?
if [ 0 != $return_code ]; then
  echo -e "$boldred--- Login failed ---$reset"
  echo "##vso[task.logissue type=error]az login failed."
  exit $return_code
fi

# Reset the account if the sourcing was done
ARM_SUBSCRIPTION_ID=$CP_ARM_SUBSCRIPTION_ID
export ARM_SUBSCRIPTION_ID
az account set --subscription "$ARM_SUBSCRIPTION_ID"
echo "Deployer subscription:               $ARM_SUBSCRIPTION_ID"

echo -e "$green--- Convert config files to UX format ---$reset"
dos2unix -q "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/$deployer_config"
dos2unix -q "${CONFIG_REPO_PATH}/LIBRARY/$library_folder/$library_config"

if [ "$(force_reset)" = "True" ]; then
  echo "##vso[task.logissue type=warning]Forcing a re-install"
  echo "Running on:            $(this_agent)"
  sed -i 's/step=1/step=0/' "$deployer_environment_file_name"
  sed -i 's/step=2/step=0/' "$deployer_environment_file_name"
  sed -i 's/step=3/step=0/' "$deployer_environment_file_name"

  export FORCE_RESET=true
  key_vault=$(getVariableFromVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "${deployer_environment_file_name}" "keyvault")
  echo "Deployer Key Vault:                  ${key_vault}"

  key_vault_id=$(az resource list --name "${key_vault}" --resource-type Microsoft.KeyVault/vaults --query "[].id | [0]" -o tsv)
  export TF_VAR_deployer_kv_user_arm_id=${key_vault_id}
  if [ -n "${key_vault_id}" ]; then
    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    az keyvault network-rule add --name "${key_vault}" --ip-address "${this_ip}" --subscription "$(Terraform_Remote_Storage_Subscription)" --only-show-errors --output none
  fi

  tfstate_resource_id=$(az resource list --name "$(Terraform_Remote_Storage_Account_Name)" --subscription "$(Terraform_Remote_Storage_Subscription)" --resource-type Microsoft.Storage/storageAccounts --query "[].id | [0]" -o tsv)
  if [ -n "${tfstate_resource_id}" ]; then
    this_ip=$(curl -s ipinfo.io/ip) >/dev/null 2>&1
    az storage account network-rule add --account-name "$(Terraform_Remote_Storage_Account_Name)" --resource-group "$(Terraform_Remote_Storage_Resource_Group_Name)" --ip-address "${this_ip}" --only-show-errors --output none
  fi

  REINSTALL_ACCOUNTNAME=$(Terraform_Remote_Storage_Account_Name)
  export REINSTALL_ACCOUNTNAME
  REINSTALL_SUBSCRIPTION=$(Terraform_Remote_Storage_Subscription)
  export REINSTALL_SUBSCRIPTION
  REINSTALL_RESOURCE_GROUP=$(Terraform_Remote_Storage_Resource_Group_Name)
  export REINSTALL_RESOURCE_GROUP
fi

echo -e "$green--- Variables ---$reset"
storage_account_parameter=""
if [ -z "${TF_VAR_ansible_core_version}" ]; then
  TF_VAR_ansible_core_version=2.17
  export TF_VAR_ansible_core_version
fi
TF_VAR_use_webapp=$(use_webapp)
export TF_VAR_use_webapp

if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/state.zip" ]; then
  # shellcheck disable=SC2001
  # shellcheck disable=SC2005
  pass=$(echo "$(System.CollectionId)" | sed 's/-//g')
  echo "Unzipping state.zip"
  unzip -qq -o -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/state.zip" -d "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder"
fi

export TF_LOG_PATH=$CONFIG_REPO_PATH/.sap_deployment_automation/terraform.log
set +eu

if [ "$USE_MSI" != "true" ]; then
  "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
    --deployer_parameter_file "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/$deployer_config" \
    --library_parameter_file "${CONFIG_REPO_PATH}/LIBRARY/$library_folder/$library_config" \
    --subscription "$ARM_SUBSCRIPTION_ID" --spn_id "$ARM_CLIENT_ID" \
    --spn_secret "$ARM_CLIENT_SECRET" --tenant_id "$ARM_TENANT_ID" \
    --auto-approve --ado --only_deployer

else
  "$SAP_AUTOMATION_REPO_PATH/deploy/scripts/deploy_controlplane.sh" \
    --deployer_parameter_file "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/$deployer_config" \
    --library_parameter_file "${CONFIG_REPO_PATH}/LIBRARY/$library_folder/$library_config" \
    --subscription "$ARM_SUBSCRIPTION_ID" --auto-approve --ado --only_deployer --msi
fi
return_code=$?
echo "Deploy_controlplane returned          $return_code."

set -eu

if [ -f "${deployer_environment_file_name}" ]; then
  file_deployer_tfstate_key=$(grep -m1 "^deployer_tfstate_key" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
  if [ -z "$file_deployer_tfstate_key" ]; then
    deployer_tfstate_key=$file_deployer_tfstate_key
    export deployer_tfstate_key
  fi
  echo "Deployer State File                   $deployer_tfstate_key"

  file_key_vault=$(grep -m1 "^keyvault=" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
  echo "Deployer Key Vault:                   ${file_key_vault}"

  file_REMOTE_STATE_SA=$(grep -m1 "^REMOTE_STATE_SA" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
  if [ -n "${file_REMOTE_STATE_SA}" ]; then
    echo "Terraform Remote State Account:       ${file_REMOTE_STATE_SA}"
  fi

  file_REMOTE_STATE_RG=$(grep -m1 "^REMOTE_STATE_RG" "${deployer_environment_file_name}" | awk -F'=' '{print $2}' | xargs || true)
  if [ -n "${file_REMOTE_STATE_SA}" ]; then
    echo "Terraform Remote State RG Name:       ${file_REMOTE_STATE_RG}"
  fi

  echo -e "$green--- Adding deployment automation configuration to devops repository ---$reset"
  added=0
  cd "$CONFIG_REPO_PATH" || exit
  git pull -q

fi
echo -e "$green--- Update repo ---$reset"
if [ -f ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}" ]; then
  git add ".sap_deployment_automation/${ENVIRONMENT}${LOCATION}"
  added=1
fi
if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/.terraform/terraform.tfstate" ]; then
  git add -f "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/.terraform/terraform.tfstate"
  added=1
fi
if [ -f "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/terraform.tfstate" ]; then
  sudo apt-get install zip -y
  # shellcheck disable=SC2001
  # shellcheck disable=SC2005
  pass=$(echo "$(System.CollectionId)" | sed 's/-//g')
  zip -q -j -P "${pass}" "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/state" "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/terraform.tfstate"
  git add -f "${CONFIG_REPO_PATH}/DEPLOYER/$deployer_folder/state.zip"
  added=1
fi
if [ 1 = $added ]; then
  git config --global user.email "$(Build.RequestedForEmail)"
  git config --global user.name "$(Build.RequestedFor)"
  git commit -m "Added updates from devops deployment $(Build.DefinitionName) [skip ci]"
  git -c http.extraheader="AUTHORIZATION: bearer $(System.AccessToken)" push --set-upstream origin "$sourceBranchName"
fi
if [ -f "$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md" ]; then
  echo "##vso[task.uploadsummary]$CONFIG_REPO_PATH/.sap_deployment_automation/${ENVIRONMENT}${LOCATION}.md"
fi
echo -e "$green--- Adding variables to the variable group: $(variable_group) ---$reset"
if [ 0 = $return_code ]; then

  saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_State_FileName" "$deployer_tfstate_key"
  saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "Deployer_Key_Vault" "$file_key_vault"
  saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ControlPlaneEnvironment" "$ENVIRONMENT"
  saveVariableInVariableGroup "${VARIABLE_GROUP_ID}" "ControlPlaneLocation" "$LOCATION"

fi
exit $return_code

#!/bin/bash

function getVariableFromVariableGroup() {
  local variable_group_id="$1"
  local variable_name="$2"
  local environment_file_name="$3"
  local environment_variable_name="$4"
  local variable_value
  local return_value=2
  variable_value=$(az pipelines variable-group variable list --group-id "${variable_group_id}" --query "[?name=='$variable_name'].value" -o tsv)
  if [ -z "${variable_value}" ]; then
    if [ -f "${environment_file_name}" ]; then
      variable_value=$(grep "^$environment_variable_name" "${environment_file_name}" | awk -F'=' '{print $2}' | xargs)
      return_value=1
    fi
  else
    echo "Variable $variable_name found in variable group $variable_group_id"
    return_value=0
  fi

  echo "$variable_value"
  exit "$return_value"
}

function saveVariableInVariableGroup() {
  local variable_group_id="$1"
  local variable_name="$2"
  local variable_value="$3"
  az_var=$(az pipelines variable-group variable list --group-id "${variable_group_id}" --query --query "[?name=='$variable_name'].value" --out tsv)
  if [ -z "${az_var}" ]; then
    az pipelines variable-group variable create --group-id "${variable_group_id}" --name "$variable_name" --value "${variable_value}" --output none --only-show-errors
  else
    az pipelines variable-group variable update --group-id "${variable_group_id}" --name "$variable_name" --value "${variable_value}" --output none --only-show-errors
  fi

}

function configureNonDeployer() {
  green="\e[1;32m"
  reset="\e[0m"
  local tf_version=$1
  local tf_url="https://releases.hashicorp.com/terraform/${tf_version}/terraform_${tf_version}_linux_amd64.zip"
  echo -e "$green--- Install dos2unix ---$reset"
  sudo apt-get -qq install dos2unix

  sudo apt-get -qq install zip

  echo -e "$green --- Install terraform ---$reset"

  wget -q "$tf_url"
  return_code=$?
  if [ 0 != $return_code ]; then
    echo "##vso[task.logissue type=error]Unable to download Terraform version $tf_version."
    exit 2
  fi
  unzip -qq "terraform_${tf_version}_linux_amd64.zip"
  sudo mv terraform /bin/
  rm -f "terraform_${tf_version}_linux_amd64.zip"

  az extension add --name storage-blob-preview --allow-preview true --output none >/dev/null

}

function LogonToAzure() {
  local useMSI=$1
  if [ "$useMSI" != "true" ]; then
    echo "Deployment credentials:              Service Principal"
    echo "Deployment credential ID (SPN):      $ARM_CLIENT_ID"
    unset ARM_USE_MSI
    az login --service-principal --username "$ARM_CLIENT_ID" --password="$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID" --output none
  else
    echo "Deployment credentials:              Managed Service Identity"
    source "/etc/profile.d/deploy_server.sh"
  fi

}

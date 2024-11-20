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

printenv

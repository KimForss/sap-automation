#!/bin/bash
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

full_script_path="$(realpath "${BASH_SOURCE[0]}")"
script_directory="$(dirname "${full_script_path}")"
parent_directory="$(dirname "$script_directory")"
SCRIPT_NAME="$(basename "$0")"

source "${parent_directory}/deploy_utils.sh"
set -e

return_code=0

if printenv APPLICATION_CONFIGURATION_NAME; then
	APPLICATION_CONFIGURATION_ID=$(az appconfig show --name "$APPLICATION_CONFIGURATION_NAME" --query "id" --output tsv)
	if [ -n "$APPLICATION_CONFIGURATION_ID" ]; then
		export APPLICATION_CONFIGURATION_ID
		echo ""
		echo "Running v2 script"
		echo ""
		"${script_directory}/v2/$SCRIPT_NAME"
	else
		echo ""
		echo "Running v1 script"
		echo ""
		"${script_directory}/v1/$SCRIPT_NAME"
	fi
else
	echo ""
	echo "Running v1 script"
	echo ""
	"${script_directory}/v1/$SCRIPT_NAME"
fi

echo "Return code: $return_code"

exit $return_code

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#######################################4#######################################8
#                                                                              #
#                                Parameters                                    #
#                                                                              #
#######################################4#######################################8

variable "assign_subscription_permissions" { description = "Assign permissions on the subscription" }
variable "authentication"                  { description = "Dictionary of authentication information" }
variable "bastion_deployment"              { description = "Value indicating if Azure Bastion should be deployed" }
variable "bastion_sku"                     { description = "The SKU of the Bastion Host. Accepted values are Basic or Standard" }
variable "bootstrap"                       { description = "Defines the phase of deployment" }
variable "configure"                       { description = "Value indicating if deployer should be configured" }
variable "infrastructure"                  { description = "Dictionary of information about the common infrastructure" }
variable "naming"                          { description = "Defines the names for the resources" }
variable "options"                         { description = "Dictionary of miscallaneous parameters" }
variable "place_delete_lock_on_resources"  { description = "If defined, a delete lock will be placed on the key resources" }
variable "ssh-timeout"                     { description = "SSH timeout" }
variable "state_filename_prefix"           { description = "State file name" }
variable "network_logical_name"            { description = "Logical name of the network" }
variable "tf_version"                      { description = "Terraform version to install on deployer" }
variable "use_private_endpoint"            { description = "Boolean value indicating if private endpoint should be used for the deployment" }
variable "use_service_endpoint"            { description = "Boolean value indicating if service endpoints should be used for the deployment" }

#########################################################################################
#                                                                                       #
#  Firewall                                                                             #
#                                                                                       #
#########################################################################################


variable "firewall"                    { description = "Dictionary of Firewall settings" }

#########################################################################################
#                                                                                       #
#  KeyVault                                                                             #
#                                                                                       #
#########################################################################################

variable "additional_users_to_add_to_keyvault_policies" { description = "List of object IDs to add to key vault policies" }
variable "enable_purge_control_for_keyvaults" { description = "Disables the purge protection for Azure keyvaults." }
variable "key_vault"                   { description = "The user brings existing Azure Key Vaults" }
variable "set_secret_expiry"           { description = "Set expiry date for secrets" }
variable "soft_delete_retention_days"  { description = "The number of days that items should be retained in the soft delete period" }


#########################################################################################
#                                                                                       #
#  Web App                                                                              #
#                                                                                       #
#########################################################################################

variable "app_registration_app_id"     { description = "App registration app id" }
variable "use_webapp"                  {
                                         description = "value indicating if webapp should be deployed"
                                         default = false
                                       }
variable "sa_connection_string"        { description = "Storage account connection string" }

variable "webapp_client_secret"        { description = "App registration client secret" }

variable "enable_firewall_for_keyvaults_and_storage" {
                                                       description = "Boolean value indicating if firewall should be enabled for key vaults and storage"
                                                       default     = false
                                                       type        = bool
                                                     }

variable "public_network_access_enabled" { description = "Defines if the public access should be enabled for keyvaults and storage accounts" }

variable "subnets_to_add"              {
                                         description = "List of subnets to add to storage account and keyvaults firewall"
                                         default     = []
                                       }

#########################################################################################
#                                                                                       #
#  DNS settings                                                                         #
#                                                                                       #
#########################################################################################

variable "dns_settings"                {
                                         description = "DNS details for the deployment"
                                         default     = {}
                                       }

###############################################################################
#                                                                             #
#                            Deployer Information                             #
#                                                                             #
###############################################################################

variable "auto_configure_deployer"     { description = "Value indicating if the deployer should be configured automatically" }
variable "deployer"                    { description = "Dictionary of information about the deployer" }
variable "deployer_vm_count"           {
                                         description = "Number of deployer VMs to create"
                                         type        = number
                                         default     = 1
                                       }
variable "arm_client_id"               { description = "ARM client id" }



#########################################################################################
#                                                                                       #
#  ADO definitions                                                                      #
#                                                                                       #
#########################################################################################

variable "agent_pool"                  { description = "If provided, contains the name of the agent pool to be used" }
variable "agent_pat"                   { description = "If provided, contains the Personal Access Token to be used" }
variable "agent_ado_url"               { description = "If provided, contains the Url to the ADO repository" }
variable "ansible_core_version"        { description = "If provided, the version of ansible core to be installed" }
variable "Agent_IP"                    { description = "If provided, contains the IP address of the agent" }
variable "spn_id"                      { description = "SPN ID to be used for the deployment" }


#######################################4#######################################8
#                                                                              #
#  Miscellaneous settings                                                      #
#                                                                              #
#######################################4#######################################8

variable "app_service"                 { description = "Details of the Application Service" }
variable "app_config_service_name"     { description = "Details of the Application Configuration Service" }

variable "additional_network_id"       { description = "Additional network ID" }


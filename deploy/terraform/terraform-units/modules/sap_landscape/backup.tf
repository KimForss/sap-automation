# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#########################################################################################
#                                                                                       #
#                            Recovery Services Vault                                    #
#                                                                                       #
#########################################################################################

resource "azurerm_recovery_services_vault" "vault" {
  provider                             = azurerm.main
  count                                = local.enable_backup ? 1 : 0
  name                                 = format("%s%s%s%s",
                                            var.naming.resource_prefixes.recovery_vault,
                                            local.prefix,
                                            var.naming.separator,
                                            local.resource_suffixes.recovery_vault
                                         )
  resource_group_name                  = local.resource_group_exists ? (
                                            data.azurerm_resource_group.resource_group[0].name) : (
                                            azurerm_resource_group.resource_group[0].name
                                         )
  location                             = local.resource_group_exists ? (
                                            data.azurerm_resource_group.resource_group[0].location) : (
                                            azurerm_resource_group.resource_group[0].location
                                         )
  sku                                  = try(var.backup.sku, "Standard")
  storage_mode_type                    = try(var.backup.storage_mode_type, "GeoRedundant")
  soft_delete_enabled                  = true
  tags                                 = var.tags

  identity {
    type                               = "SystemAssigned"
  }
}

#########################################################################################
#                                                                                       #
#                            Backup Policies                                            #
#                                                                                       #
#########################################################################################

resource "azurerm_backup_policy_vm" "vm_backup_policy" {
  provider                             = azurerm.main
  for_each                             = local.enable_backup ? var.backup.backup_policies : {}

  name                                 = each.key
  resource_group_name                  = local.resource_group_exists ? (
                                            data.azurerm_resource_group.resource_group[0].name) : (
                                            azurerm_resource_group.resource_group[0].name
                                         )
  recovery_vault_name                  = azurerm_recovery_services_vault.vault[0].name

  timezone                             = try(each.value.timezone, "UTC")

  # Backup schedule
  backup {
    frequency                          = each.value.frequency
    time                               = each.value.time
    weekdays                           = each.value.frequency == "Weekly" ? each.value.weekdays : null
  }

  # Retention settings for daily backups
  retention_daily {
    count                              = each.value.retention_daily_count
  }

  # Retention settings for weekly backups (if configured)
  dynamic "retention_weekly" {
    for_each                           = try(each.value.retention_weekly_count, 0) > 0 ? [1] : []
    content {
      count                            = each.value.retention_weekly_count
      weekdays                         = each.value.retention_weekly_days
    }
  }

  # Retention settings for monthly backups (if configured)
  dynamic "retention_monthly" {
    for_each                           = try(each.value.retention_monthly_count, 0) > 0 ? [1] : []
    content {
      count                            = each.value.retention_monthly_count
      weekdays                         = each.value.retention_monthly_days
      weeks                            = each.value.retention_monthly_weeks
    }
  }

  # Retention settings for yearly backups (if configured)
  dynamic "retention_yearly" {
    for_each                           = try(each.value.retention_yearly_count, 0) > 0 ? [1] : []
    content {
      count                            = each.value.retention_yearly_count
      weekdays                         = each.value.retention_yearly_days
      weeks                            = each.value.retention_yearly_weeks
      months                           = each.value.retention_yearly_months
    }
  }
}

#########################################################################################
#                                                                                       #
#                        VM Protection / Backup Registration                            #
#                                                                                       #
#########################################################################################

# Enable backup for utility VMs if they exist and backup is enabled
resource "azurerm_backup_protected_vm" "utility_vm_backup" {
  provider                             = azurerm.main
  count                                = (local.enable_backup &&
                                         var.vm_settings.count > 0 &&
                                         try(var.backup.enable_utility_vm_backup, false) &&
                                         (
                                           length(try(var.backup.utility_vm_backup_policy_linux, "")) > 0 ||
                                           length(try(var.backup.utility_vm_backup_policy_windows, "")) > 0
                                         )) ? var.vm_settings.count : 0

  resource_group_name                  = local.resource_group_exists ? (
                                            data.azurerm_resource_group.resource_group[0].name) : (
                                            azurerm_resource_group.resource_group[0].name
                                         )
  recovery_vault_name                  = azurerm_recovery_services_vault.vault[0].name

  # Select the appropriate backup policy based on OS type
  backup_policy_id                     = azurerm_backup_policy_vm.vm_backup_policy[
                                           upper(var.vm_settings.image.os_type) == "LINUX" ?
                                           var.backup.utility_vm_backup_policy_linux :
                                           var.backup.utility_vm_backup_policy_windows
                                         ].id

  # Reference the correct VM based on OS type
  source_vm_id                         = upper(var.vm_settings.image.os_type) == "LINUX" ? (
                                           azurerm_linux_virtual_machine.utility_vm[count.index].id ) : (
                                           azurerm_windows_virtual_machine.utility_vm[count.index].id )
}

# Enable backup for iSCSI VMs if they exist and backup is enabled
resource "azurerm_backup_protected_vm" "iscsi_vm_backup" {
  provider                             = azurerm.main
  count                                = (local.enable_backup &&
                                         local.enable_iscsi &&
                                         try(var.backup.enable_iscsi_backup, false) &&
                                         length(try(var.backup.iscsi_backup_policy_name, "")) > 0) ? (
                                         local.iscsi_count ) : 0

  resource_group_name                  = local.resource_group_exists ? (
                                            data.azurerm_resource_group.resource_group[0].name) : (
                                            azurerm_resource_group.resource_group[0].name
                                         )
  recovery_vault_name                  = azurerm_recovery_services_vault.vault[0].name

  # Use the specified backup policy
  backup_policy_id                     = azurerm_backup_policy_vm.vm_backup_policy[var.backup.iscsi_backup_policy_name].id

  source_vm_id                         = azurerm_linux_virtual_machine.iscsi[count.index].id
}

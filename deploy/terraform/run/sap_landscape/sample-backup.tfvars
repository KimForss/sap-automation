# Backup settings
enable_backup                          = true
backup_storage_mode                    = "LocallyRedundant"  # Options: "GeoRedundant", "LocallyRedundant", "ZoneRedundant"
backup_sku                             = "Standard"          # Options: "Standard", "RS0"

# Backup policies configuration
backup_policies                        = {
                                           "daily-policy" = {
                                             frequency              = "Daily"
                                             time                   = "23:00"
                                             retention_daily_count  = 14
                                             # Optional weekly retention settings
                                             retention_weekly_count = 0
                                             # Optional monthly retention settings
                                             retention_monthly_count = 0
                                             # Optional yearly retention settings
                                             retention_yearly_count = 0
                                           },
                                           "weekly-policy" = {
                                             frequency               = "Weekly"
                                             time                    = "23:00"
                                             weekdays                = ["Sunday"]
                                             retention_daily_count   = 7
                                             # Weekly retention settings
                                             retention_weekly_count  = 4
                                             retention_weekly_days   = ["Sunday"]
                                             # Optional monthly retention settings
                                             retention_monthly_count = 0
                                             # Optional yearly retention settings
                                             retention_yearly_count  = 0
                                           },
                                           "monthly-policy" = {
                                             frequency               = "Monthly"
                                             time                    = "02:00"
                                             weekdays                = ["Sunday"]
                                             retention_daily_count   = 7
                                             # Weekly retention settings
                                             retention_weekly_count  = 4
                                             retention_weekly_days   = ["Sunday"]
                                             # Monthly retention settings
                                             retention_monthly_count = 12
                                             retention_monthly_days  = ["Sunday"]
                                             retention_monthly_weeks = ["First"]
                                             # Optional yearly retention settings
                                             retention_yearly_count  = 0
                                           },
                                           "yearly-policy" = {
                                             frequency               = "Monthly"  # Note: Azure doesn't have yearly frequency, we use monthly with yearly retention
                                             time                    = "03:00"
                                             weekdays                = ["Sunday"]
                                             retention_daily_count   = 7
                                             # Weekly retention settings
                                             retention_weekly_count  = 4
                                             retention_weekly_days   = ["Sunday"]
                                             # Monthly retention settings
                                             retention_monthly_count = 12
                                             retention_monthly_days  = ["Sunday"]
                                             retention_monthly_weeks = ["First"]
                                             # Yearly retention settings
                                             retention_yearly_count  = 7
                                             retention_yearly_days   = ["Sunday"]
                                             retention_yearly_weeks  = ["First"]
                                             retention_yearly_months = ["January"]
                                           }
                                         }

# Utility VM backup settings
enable_utility_vm_backup               = true
utility_vm_backup_policy_linux         = "daily-policy"
utility_vm_backup_policy_windows       = "weekly-policy"

# ISCSI backup settings
enable_iscsi_backup                    = true
iscsi_backup_policy                    = "monthly-policy"

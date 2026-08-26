variable "aws_account_id" {
  description = "AWS account ID used for IAM trust conditions."
  type        = string
}

variable "vpc_id" {
  description = "Primary-region VPC ID."
  type        = string
}

variable "cluster_name" {
  description = "Primary cluster name. This is used for tagging the resources"
  type        = string
}

variable "secondary_cluster_name" {
  description = "Secondary cluster name."
  type        = string
}

variable "disable_default_tags" {
  description = "Disable default tags added by this module."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Base tags for all global/secondary resources."
  type        = map(string)
  default     = {}
}

variable "truefoundry_aurora_global_cluster_identifier" {
  description = "Global Aurora cluster identifier."
  type        = string

  validation {
    condition     = length(var.truefoundry_aurora_global_cluster_identifier) <= 63
    error_message = "truefoundry_aurora_global_cluster_identifier must be 63 characters or fewer."
  }
}

variable "truefoundry_db_port" {
  description = "Database port."
  type        = number
  default     = 5432
}

variable "truefoundry_db_engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
  default     = "17.5"
}

variable "truefoundry_db_security_group_name_override_enabled" {
  description = "Enable override for the module-created secondary DB security group name."
  type        = bool
  default     = false
}

variable "truefoundry_db_security_group_name_override" {
  description = "Override name for the module-created secondary DB security group when truefoundry_db_security_group_name_override_enabled is true."
  type        = string
  default     = ""
  validation {
    condition     = var.truefoundry_db_security_group_name_override_enabled ? trimspace(var.truefoundry_db_security_group_name_override) != "" : true
    error_message = "truefoundry_db_security_group_name_override must be set when truefoundry_db_security_group_name_override_enabled is true."
  }
}

variable "truefoundry_db_subnet_group_name_override_enabled" {
  description = "Enable override for the module-created secondary DB subnet group name."
  type        = bool
  default     = false
}

variable "truefoundry_db_subnet_group_name_override" {
  description = "Override name for the module-created secondary DB subnet group when truefoundry_db_subnet_group_name_override_enabled is true."
  type        = string
  default     = ""
  validation {
    condition     = var.truefoundry_db_subnet_group_name_override_enabled ? trimspace(var.truefoundry_db_subnet_group_name_override) != "" : true
    error_message = "truefoundry_db_subnet_group_name_override must be set when truefoundry_db_subnet_group_name_override_enabled is true."
  }
}

variable "truefoundry_db_deletion_protection" {
  description = "Whether to enable deletion protection."
  type        = bool
  default     = true
}

variable "truefoundry_db_skip_final_snapshot" {
  description = "Whether to skip final snapshot on deletion."
  type        = bool
  default     = false
}

variable "truefoundry_db_storage_encrypted" {
  description = "Whether to enable storage encryption."
  type        = bool
  default     = true
}

variable "truefoundry_db_postgres_parameter_group_enabled" {
  description = "Whether to create and attach Aurora parameter groups."
  type        = bool
  default     = true
}

variable "truefoundry_db_postgres_parameter_group_override_enabled" {
  description = "Enable override for the module-created secondary Aurora parameter group name."
  type        = bool
  default     = false
}

variable "truefoundry_db_postgres_parameter_group_override_name" {
  description = "Override name for the module-created secondary Aurora parameter group when truefoundry_db_postgres_parameter_group_override_enabled is true."
  type        = string
  default     = ""
  validation {
    condition     = var.truefoundry_db_postgres_parameter_group_override_enabled ? trimspace(var.truefoundry_db_postgres_parameter_group_override_name) != "" : true
    error_message = "truefoundry_db_postgres_parameter_group_override_name must be set when truefoundry_db_postgres_parameter_group_override_enabled is true."
  }
}

variable "truefoundry_db_aurora_cloudwatch_log_exports" {
  description = "Aurora-compatible CloudWatch log exports."
  type        = list(string)
  default     = ["postgresql"]
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication for Aurora clusters."
  type        = bool
  default     = false
}

variable "truefoundry_aurora_secondary_config" {
  description = "Configuration for Aurora secondary cluster in the DR region."
  type = object({
    cluster_identifier                      = optional(string, "")
    vpc_id                                  = string
    subnet_ids                              = list(string)
    instance_class                          = optional(string, "db.r7g.large")
    instance_count                          = optional(number, 1)
    instances_identifier                    = optional(list(string), [])
    ingress_cidr_blocks                     = optional(list(string), [])
    ingress_security_group_ids              = optional(list(string), [])
    additional_security_group_ids           = optional(list(string), [])
    publicly_accessible                     = optional(bool, false)
    backup_retention_period                 = optional(number, 14)
    kms_key_id                              = optional(string, null)
    enable_insights                         = optional(bool, true)
    enable_monitoring                       = optional(bool, true)
    monitoring_interval                     = optional(number, 60)
    monitoring_role_enable_override         = optional(bool, false)
    monitoring_role_arn                     = optional(string, "")
    monitoring_role_name_override_enabled   = optional(bool, false)
    monitoring_role_name_override           = optional(string, "")
    monitoring_role_permission_boundary_arn = optional(string, null)
    postgres_parameter_group_parameters     = optional(list(object({
      name  = string
      value = string
      apply_method = optional(string)
    })), [{
      name = "rds.force_ssl"
      value = "0"
      apply_method = "immediate"
    }])
    tags                                    = optional(map(string), {})
  })

  validation {
    condition = (
      !var.truefoundry_aurora_secondary_config.monitoring_role_enable_override ||
      trimspace(var.truefoundry_aurora_secondary_config.monitoring_role_arn) != ""
    )
    error_message = "truefoundry_aurora_secondary_config.monitoring_role_arn must be set when monitoring_role_enable_override is true."
  }

  validation {
    condition = (
      !var.truefoundry_aurora_secondary_config.monitoring_role_name_override_enabled ||
      trimspace(var.truefoundry_aurora_secondary_config.monitoring_role_name_override) != ""
    )
    error_message = "truefoundry_aurora_secondary_config.monitoring_role_name_override must be set when monitoring_role_name_override_enabled is true."
  }

  validation {
    condition = (
      !var.truefoundry_aurora_secondary_config.monitoring_role_name_override_enabled ||
      length(var.truefoundry_aurora_secondary_config.monitoring_role_name_override) <= 64
    )
    error_message = "truefoundry_aurora_secondary_config.monitoring_role_name_override must be 64 characters or fewer."
  }

  validation {
    condition = !(
      var.truefoundry_aurora_secondary_config.monitoring_role_enable_override &&
      var.truefoundry_aurora_secondary_config.monitoring_role_name_override_enabled
    )
    error_message = "Use either external monitoring role override (monitoring_role_enable_override + monitoring_role_arn) or monitoring role name override, not both."
  }
}

variable "truefoundry_aurora_enable_automated_failover" {
  description = "Enable automated global failover pipeline in DR region."
  type        = bool
  default     = false
}

variable "truefoundry_aurora_alert_email" {
  description = "Email address for failover alerts."
  type        = string
  default     = ""
}

variable "truefoundry_aurora_alarm_evaluation_periods" {
  description = "CloudWatch evaluation periods for replication lag alarm."
  type        = number
  default     = 3
}

variable "truefoundry_aurora_alarm_treat_missing_data" {
  description = "How CloudWatch alarm treats missing replication lag datapoints."
  type        = string
  default     = "missing"
}

variable "truefoundry_aurora_vpc_peering_enabled" {
  description = "Create cross-region VPC peering between primary and DR VPCs."
  type        = bool
  default     = false
}

variable "truefoundry_aurora_vpc_peering_primary_route_table_ids" {
  description = "Primary VPC route table IDs to route DR CIDR through peering."
  type        = list(string)
  default     = []
}

variable "truefoundry_aurora_vpc_peering_dr_route_table_ids" {
  description = "DR VPC route table IDs to route primary CIDR through peering."
  type        = list(string)
  default     = []
}

variable "truefoundry_aurora_vpc_peering_allow_remote_dns_resolution" {
  description = "Enable DNS resolution across VPC peering."
  type        = bool
  default     = true
}


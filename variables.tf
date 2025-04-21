##################################################################################
## Generic
##################################################################################
variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The oidc url of the eks cluster"
  type        = string
}

variable "aws_region" {
  description = "EKS Cluster region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS Tags common to all the resources created"
}

##################################################################################
## network
##################################################################################

variable "vpc_id" {
  type        = string
  description = "AWS VPC to deploy Truefoundry rds"
}

##################################################################################
## Database
##################################################################################

variable "truefoundry_db_enabled" {
  type        = bool
  description = "variable to enable/disable truefoundry db creation"
  default     = true
}

variable "truefoundry_db_database_name" {
  type        = string
  description = "Name of the database in DB"
  default     = "ctl"
}

variable "truefoundry_db_ingress_security_group" {
  type        = string
  description = "SG allowed to connect to the database"
  default     = ""

  validation {
    condition     = var.truefoundry_db_enabled ? var.truefoundry_db_ingress_security_group != "" : true
    error_message = "truefoundry_db_ingress_security_group is required when truefoundry_db_enabled is true"
  }
}

variable "truefoundry_db_ingress_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect to the database"
  default     = []
}

variable "truefoundry_db_subnet_ids" {
  type        = list(string)
  description = "List of subnets where the RDS database will be deployed"
  default     = []

  validation {
    condition     = var.truefoundry_db_enabled ? length(var.truefoundry_db_subnet_ids) > 0 : true
    error_message = "truefoundry_db_subnet_ids is required when truefoundry_db_enabled is true"
  }
}

variable "truefoundry_db_instance_class" {
  type        = string
  description = "Instance class for RDS"
  default     = "db.t3.medium"
}

variable "truefoundry_db_publicly_accessible" {
  type        = string
  default     = false
  description = "Make database publicly accessible. Subnets and SG must match"
}

variable "truefoundry_db_backup_retention_period" {
  type        = number
  default     = 14
  description = "Backup retention period for RDS"
}

variable "truefoundry_db_allocated_storage" {
  type        = string
  description = "Storage for RDS. Minimum storage allowed for gp3 volumes is 20GB"
  default     = "20"
}

variable "truefoundry_db_max_allocated_storage" {
  type        = string
  description = "Max allowed storage for RDS when autoscaling is enabled"
  default     = "30"
}

variable "truefoundry_db_storage_type" {
  type        = string
  description = "Storage type for truefoundry db"
  default     = "gp3"
}

variable "truefoundry_db_storage_iops" {
  type        = number
  description = "Provisioned IOPS for the db"
  default     = 0
}

variable "truefoundry_db_skip_final_snapshot" {
  type    = bool
  default = false
}

variable "truefoundry_db_deletion_protection" {
  type    = bool
  default = true
}

variable "truefoundry_db_storage_encrypted" {
  type    = bool
  default = true
}

variable "truefoundry_db_engine_version" {
  default     = "13.15"
  type        = string
  description = "Truefoundry DB Postgres version"
}

variable "truefoundry_db_enable_override" {
  description = "Enable override for truefoundry db name. You must pass truefoundry_db_override_name"
  type        = bool
  default     = false
}

variable "truefoundry_db_override_name" {
  description = "Override name for truefoundry db.This is the name of the RDS resources in AWS . truefoundry_db_enable_override must be set true"
  type        = string
  default     = ""
  validation {
    condition     = length(var.truefoundry_db_override_name) <= 63
    error_message = "Error: DB Instance name is too long."
  }
}

variable "truefoundry_db_enable_insights" {
  description = "Enable insights to truefoundry db"
  type        = bool
  default     = false
}

variable "truefoundry_cloudwatch_log_exports" {
  description = "Set of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "truefoundry_db_multiple_az" {
  description = "Enable Multi-az (standby) instances for RDS instances"
  type        = bool
  default     = false
}

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = false
}

variable "manage_master_user_password" {
  description = "Enable master user password management. If set to true master user management is done by RDS in secrets manager, if false a random password is generated"
  type        = bool
  default     = false
}

variable "manage_master_user_password_rotation" {
  description = "Enable master user password rotation"
  type        = bool
  default     = false
}

variable "master_user_password_rotate_immediately" {
  description = "Rotate master user password immediately"
  type        = bool
  default     = false
}

variable "master_user_password_rotation_automatically_after_days" {
  description = "Rotate master user password automatically after days"
  type        = number
  default     = 90
}

variable "master_user_password_rotation_duration" {
  description = "Master user password rotation duration"
  type        = string
  default     = "3h"
}

##################################################################################
## Mlfoundry bucket
##################################################################################

variable "truefoundry_s3_enabled" {
  type        = bool
  description = "variable to enable/disable truefoundry s3 bucket creation"
  default     = true
}

variable "truefoundry_s3_enable_override" {
  description = "Enable override for s3 bucket name. You must pass truefoundry_s3_override_name"
  type        = bool
  default     = false
}

variable "truefoundry_s3_override_name" {
  description = "Override name for s3 bucket. truefoundry_s3_enable_override must be set true"
  type        = string
  default     = ""

  validation {
    condition     = length(var.truefoundry_s3_override_name) <= 63
    error_message = "Error: Bucket name is too long."
  }
}

variable "truefoundry_artifact_buckets_will_read" {
  description = "A list of bucket IDs mlfoundry will need read access to, in order to show the stored artifacts. It accepts any valid IAM resource, including ARNs with wildcards, so you can do something like arn:aws:s3:::bucket-prefix-*"
  type        = list(string)
  default     = []
}

variable "truefoundry_s3_encryption_algorithm" {
  description = "Algorithm used for encrypting the default bucket."
  type        = string
  default     = "AES256"
}

variable "truefoundry_s3_force_destroy" {
  description = "Force destroy for mlfoundry s3 bucket"
  default     = false
  type        = bool
}

variable "truefoundry_s3_encryption_key_arn" {
  description = "ARN of the key used to encrypt the bucket. Only needed if you set aws:kms as encryption algorithm."
  type        = string
  default     = null
}

variable "truefoundry_s3_cors_origins" {
  description = "List of CORS origins for Mlfoundry bucket"
  type        = list(string)
  default     = ["*"]
}

variable "blob_storage_extra_tags" {
  description = "Extra tags for the s3 bucket"
  type        = map(string)
  default     = {}
}

##################################################################################
## MLfoundry service account
##################################################################################

variable "mlfoundry_k8s_service_account" {
  description = "The k8s mlfoundry service account name"
  type        = string
  default     = "mlfoundry-server"
}

variable "mlfoundry_k8s_namespace" {
  description = "The k8s mlfoundry namespace"
  type        = string
  default     = "truefoundry"
}

##################################################################################
## Servicefoundry service account
##################################################################################

variable "svcfoundry_k8s_service_account" {
  description = "The k8s svcfoundry service account name"
  type        = string
  default     = "servicefoundry-server"
}

variable "svcfoundry_k8s_namespace" {
  description = "The k8s svcfoundry namespace"
  type        = string
  default     = "truefoundry"
}

##################################################################################
## TFy workflow admin service account
##################################################################################

variable "tfy_workflow_admin_k8s_service_account" {
  description = "The k8s tfy workflow admin service account name"
  type        = string
  default     = "tfy-workflow-admin"
}

variable "tfy_workflow_admin_k8s_namespace" {
  description = "The k8s tfy workflow admin namespace"
  type        = string
  default     = "truefoundry"
}

##################################################################################
## TFY llm-gateway service account
##################################################################################

variable "tfy_llm_gateway_k8s_namespace" {
  description = "Truefoundry k8s llm-gateway service account name"
  type        = string
  default     = "tfy-llm-gateway"
}


variable "tfy_llm_gateway_k8s_service_account" {
  description = "Truefoundry k8s namespace"
  type        = string
  default     = "truefoundry"
}

##################################################################################
## Truefoundry service account
##################################################################################

variable "truefoundry_service_account" {
  description = "Truefoundry k8s service account name"
  type        = string
  default     = "truefoundry"
}


variable "truefoundry_k8s_namespace" {
  description = "Truefoundry k8s namespace"
  type        = string
  default     = "truefoundry"
}


##################################################################################
## IAM role
##################################################################################

variable "truefoundry_iam_role_enabled" {
  default     = true
  type        = bool
  description = "variable to enable/disable truefoundry iam role creation"
}

variable "truefoundry_iam_role_enable_override" {
  default     = false
  type        = bool
  description = "Enable overriding the truefoundry IAM role name. You need to pass truefoundry_iam_role_override_name to pass the role name"
}

variable "truefoundry_iam_role_override_name" {
  default     = ""
  type        = string
  description = "Truefoundry IAM role name"
}

variable "truefoundry_iam_role_additional_oidc_subjects" {
  default     = []
  type        = list(string)
  description = "List of fully qualifies oidc subjects that can assume the truefoundry IAM role"
}

variable "truefoundry_iam_role_additional_policies_arn" {
  default     = []
  type        = list(string)
  description = "List of ARN of policies that you want to attach to the "
}
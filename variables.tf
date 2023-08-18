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

variable "account_name" {
  description = "AWS Account Name"
  type        = string
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS Tags common to all the resources created"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC to deploy Truefoundry rds"
}

#### Control Plane Components Database (truefoundry_db)

variable "truefoundry_db_ingress_security_group" {
  type        = string
  description = "SG allowed to connect to the database"
}

variable "truefoundry_db_subnet_ids" {
  type        = list(string)
  description = "List of subnets where the RDS database will be deployed"
}

variable "truefoundry_db_instance_class" {
  type        = string
  description = "Instance class for RDS"
}

variable "truefoundry_db_publicly_accessible" {
  type        = string
  default     = false
  description = "Make database publicly accessible. Subnets and SG must match"
}

variable "truefoundry_db_allocated_storage" {
  type        = string
  description = "Storage for RDS"
}

variable "truefoundry_db_storage_type" {
  type        = string
  description = "Storage type for truefoundry db"
}

variable "truefoundry_db_storage_iops" {
  type        = number
  description = "Provisioned IOPS for the db"
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
  default     = "13.10"
  type        = string
  description = "Truefoundry DB Postgres version"
}

variable "truefoundry_db_enable_override" {
  description = "Enable override for truefoundry db name. You must pass truefoundry_db_override_name"
  type        = bool
  default     = false
}
variable "truefoundry_db_override_name" {
  description = "Override name for truefoundry db. truefoundry_db_enable_override must be set true"
  type        = string
  default     = ""
  validation {
    condition     = length(var.truefoundry_db_override_name) <= 63
    error_message = "Error: DB Instance name is too long."
  }
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


###### MLFoundry

variable "mlfoundry_name" {
  description = "Name of mlfoundry deployment"
  type        = string
}


variable "mlfoundry_k8s_service_account" {
  description = "The k8s mlfoundry service account name"
  type        = string
}

variable "mlfoundry_k8s_namespace" {
  description = "The k8s mlfoundry namespace"
  type        = string
}

###### mlmonitoring

variable "mlmonitoring_name" {
  description = "Name of mlmonitoring deployment"
  type        = string
}

variable "mlmonitoring_k8s_service_account" {
  description = "The k8s mlmonitoring service account name"
  type        = string
}

variable "mlmonitoring_k8s_namespace" {
  description = "The k8s mlmonitoring namespace"
  type        = string
}

###### svcfoundry

variable "svcfoundry_name" {
  description = "Name of svcfoundry deployment"
  type        = string
}

variable "svcfoundry_k8s_service_account" {
  description = "The k8s svcfoundry service account name"
  type        = string
}

variable "svcfoundry_k8s_namespace" {
  description = "The k8s svcfoundry namespace"
  type        = string
}
variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "devtest-admin"
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "dr_region" {
  description = "DR AWS region for Aurora secondary cluster"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Cluster name used for resource naming"
  type        = string
  default     = "tfy-test"
}

# Set to "rds" to test RDS mode, "aurora" to test Aurora mode
variable "db_engine_mode" {
  description = "Database engine mode: rds or aurora"
  type        = string
  default     = "rds"
}

variable "enable_global_cluster" {
  description = "Enable Aurora Global Database with a secondary in the DR region"
  type        = bool
  default     = false
}

variable "primary_vpc_id" {
  type = string
}

variable "primary_subnet_ids" {
  type = list(string)
}

variable "primary_ingress_cidr_blocks" {
  type    = list(string)
  default = ["10.10.0.0/16"]
}

variable "dr_vpc_id" {
  type    = string
  default = ""
}

variable "dr_subnet_ids" {
  type    = list(string)
  default = []
}

variable "dr_ingress_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the DR database. Recommended over SG IDs for cross-region."
  type        = list(string)
  default     = []
}

variable "dr_ingress_security_group_ids" {
  description = "Security group IDs allowed to connect to the DR database. Must be SGs in the DR region's VPC — primary-region SG IDs will NOT work."
  type        = list(string)
  default     = []
}

variable "ingress_security_group" {
  description = "Security group ID allowed to connect to the primary database (must be in the primary region's VPC)"
  type        = string
}

variable "create_vpc_peering" {
  description = "Create VPC peering between primary and DR VPCs. Set to false if connectivity already exists (Transit Gateway, existing peering, VPN)."
  type        = bool
  default     = false
}

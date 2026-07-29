##################################################################################
## Database outputs (mode-aware: returns RDS or Aurora values)
##################################################################################

output "truefoundry_db_id" {
  description = "Database identifier (RDS instance ID or Aurora cluster ID)"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].id :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].id :
    ""
  )
}

output "truefoundry_db_endpoint" {
  description = "Database connection endpoint in address:port format"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].endpoint :
    local.aurora_enabled ? "${aws_rds_cluster.truefoundry_aurora[0].endpoint}:${aws_rds_cluster.truefoundry_aurora[0].port}" :
    ""
  )
}

output "truefoundry_db_address" {
  description = "Database hostname"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].address :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].endpoint :
    ""
  )
}

output "truefoundry_db_port" {
  description = "Database port"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].port :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].port :
    0
  )
}

output "truefoundry_db_database_name" {
  description = "Database name"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].db_name :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].database_name :
    ""
  )
}

output "truefoundry_db_engine" {
  description = "Database engine type"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].engine :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].engine :
    ""
  )
}

output "truefoundry_db_username" {
  description = "Database master username"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].username :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].master_username :
    ""
  )
}

output "truefoundry_db_password" {
  description = "Database master password"
  value = (
    local.rds_enabled ? aws_db_instance.truefoundry_db[0].password :
    local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].master_password :
    ""
  )
  sensitive = true
}

output "truefoundry_db_engine_mode" {
  description = "Active database engine mode"
  value       = var.truefoundry_db_enabled ? var.truefoundry_db_engine_mode : ""
}

##################################################################################
## Aurora-specific outputs
##################################################################################

output "truefoundry_aurora_cluster_id" {
  description = "Aurora cluster identifier"
  value       = local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].id : ""
}

output "truefoundry_aurora_cluster_arn" {
  description = "Aurora cluster ARN"
  value       = local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].arn : ""
}

output "truefoundry_aurora_cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].endpoint : ""
}

output "truefoundry_aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].reader_endpoint : ""
}

output "truefoundry_aurora_cluster_port" {
  description = "Aurora cluster port"
  value       = local.aurora_enabled ? aws_rds_cluster.truefoundry_aurora[0].port : 0
}

##################################################################################
## Non-database outputs
##################################################################################

output "truefoundry_bucket_id" {
  value = var.truefoundry_s3_enabled ? module.truefoundry_bucket[0].s3_bucket_id : ""
}

output "truefoundry_iam_role_arn" {
  value = var.truefoundry_iam_role_enabled ? module.truefoundry_oidc_iam[0].iam_role_arn : ""
}

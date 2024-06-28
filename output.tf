output "truefoundry_db_id" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].id : ""
}

output "truefoundry_db_endpoint" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].endpoint : ""
}

output "truefoundry_db_address" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].address : ""
}

output "truefoundry_db_port" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].port : 0
}

output "truefoundry_db_database_name" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].db_name : ""
}

output "truefoundry_db_engine" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].engine : ""
}

output "truefoundry_db_username" {
  value = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].username : ""
}

output "truefoundry_db_password" {
  value     = var.truefoundry_db_enabled ? aws_db_instance.truefoundry_db[0].password : ""
  sensitive = true
}

output "truefoundry_bucket_id" {
  value = var.truefoundry_s3_enabled ? module.truefoundry_bucket[0].s3_bucket_id : ""
}

output "truefoundry_iam_role_arn" {
  value = var.truefoundry_iam_role_enabled ? module.truefoundry_oidc_iam[0].iam_role_arn : ""
}
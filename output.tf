output "truefoundry_db_id" {
  value = aws_db_instance.truefoundry_db.id
}

output "truefoundry_db_endpoint" {
  value = aws_db_instance.truefoundry_db.endpoint
}

output "truefoundry_db_address" {
  value = aws_db_instance.truefoundry_db.address
}

output "truefoundry_db_port" {
  value = aws_db_instance.truefoundry_db.port
}

output "truefoundry_db_database_name" {
  value = aws_db_instance.truefoundry_db.db_name
}

output "truefoundry_db_engine" {
  value = aws_db_instance.truefoundry_db.engine
}

output "truefoundry_db_username" {
  value = aws_db_instance.truefoundry_db.username
}

output "truefoundry_db_password" {
  value     = aws_db_instance.truefoundry_db.password
  sensitive = true
}

output "truefoundry_bucket_id" {
  value = module.truefoundry_bucket.s3_bucket_id
}

output "truefoundry_iam_role_arn" {
  value = module.truefoundry_oidc_iam.iam_role_arn
}
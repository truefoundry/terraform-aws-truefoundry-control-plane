output "db_engine_mode" {
  value = module.control_plane.truefoundry_db_engine_mode
}

output "db_endpoint" {
  value = module.control_plane.truefoundry_db_endpoint
}

output "db_address" {
  value = module.control_plane.truefoundry_db_address
}

output "db_port" {
  value = module.control_plane.truefoundry_db_port
}

output "db_database_name" {
  value = module.control_plane.truefoundry_db_database_name
}

output "db_username" {
  value = module.control_plane.truefoundry_db_username
}

output "db_password" {
  value     = module.control_plane.truefoundry_db_password
  sensitive = true
}

output "aurora_cluster_endpoint" {
  value = module.control_plane.truefoundry_aurora_cluster_endpoint
}

output "aurora_cluster_reader_endpoint" {
  value = module.control_plane.truefoundry_aurora_cluster_reader_endpoint
}

output "aurora_global_cluster_id" {
  value = module.control_plane.truefoundry_aurora_global_cluster_id
}

output "aurora_secondary_endpoint" {
  value = module.control_plane.truefoundry_aurora_secondary_cluster_endpoint
}

output "aurora_secondary_reader_endpoint" {
  value = module.control_plane.truefoundry_aurora_secondary_cluster_reader_endpoint
}

output "vpc_peering_id" {
  value = var.enable_global_cluster && var.create_vpc_peering ? aws_vpc_peering_connection.primary_to_dr[0].id : ""
}

output "vpc_peering_status" {
  value = var.enable_global_cluster && var.create_vpc_peering ? aws_vpc_peering_connection_accepter.dr_accept[0].accept_status : ""
}

output "bucket_id" {
  value = module.control_plane.truefoundry_bucket_id
}

output "iam_role_arn" {
  value = module.control_plane.truefoundry_iam_role_arn
}
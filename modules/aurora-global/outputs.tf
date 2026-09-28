output "truefoundry_aurora_global_cluster_id" {
  description = "Aurora Global Database cluster identifier"
  value       = aws_rds_global_cluster.truefoundry.id
}

output "truefoundry_aurora_global_cluster_arn" {
  description = "Aurora Global Database cluster ARN"
  value       = aws_rds_global_cluster.truefoundry.arn
}

output "truefoundry_aurora_secondary_cluster_id" {
  description = "Secondary Aurora cluster identifier"
  value       = aws_rds_cluster.truefoundry_aurora_secondary.id
}

output "truefoundry_aurora_secondary_cluster_arn" {
  description = "Secondary Aurora cluster ARN"
  value       = aws_rds_cluster.truefoundry_aurora_secondary.arn
}

output "truefoundry_aurora_secondary_cluster_endpoint" {
  description = "Secondary Aurora cluster endpoint (read-only until promoted)"
  value       = aws_rds_cluster.truefoundry_aurora_secondary.endpoint
}

output "truefoundry_aurora_secondary_cluster_reader_endpoint" {
  description = "Secondary Aurora cluster reader endpoint"
  value       = aws_rds_cluster.truefoundry_aurora_secondary.reader_endpoint
}
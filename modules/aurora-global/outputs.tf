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

output "truefoundry_aurora_vpc_peering_id" {
  description = "Cross-region VPC peering connection ID. Empty when peering is disabled."
  value       = local.vpc_peering_enabled ? aws_vpc_peering_connection.primary_to_dr[0].id : ""
}

output "truefoundry_aurora_vpc_peering_status" {
  description = "Cross-region VPC peering accepter status (e.g. active). Empty when peering is disabled."
  value       = local.vpc_peering_enabled ? aws_vpc_peering_connection_accepter.secondary[0].accept_status : ""
}

# output "truefoundry_aurora_failover_lambda_name" {
#   description = "Name of the automated failover Lambda function"
#   value       = aws_lambda_function.failover.function_name
# }

# output "truefoundry_aurora_failover_sns_topic_arn" {
#   description = "ARN of the SNS topic for failover alerts"
#   value       = aws_sns_topic.failover_alerts.arn
# }

# output "truefoundry_aurora_failover_alarm_name" {
#   description = "Name of the CloudWatch alarm monitoring replication lag"
#   value       = aws_cloudwatch_metric_alarm.replication_lag.alarm_name
# }

# output "truefoundry_aurora_failover_test_command" {
#   description = "CLI command to test the failover Lambda without triggering a real failover"
#   value       = "aws lambda invoke --function-name ${aws_lambda_function.failover.function_name} --payload '{\"source\": \"manual-test\"}' --region ${data.aws_region.secondary.region} response.json && cat response.json"
# }

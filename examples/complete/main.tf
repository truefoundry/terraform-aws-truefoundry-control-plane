module "control_plane" {
  source = "../../"
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }

  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = "https://oidc.eks.${var.primary_region}.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  aws_region              = var.primary_region
  aws_account_id          = data.aws_caller_identity.current.account_id
  vpc_id                  = var.primary_vpc_id

  # Database
  truefoundry_db_enabled                 = true
  truefoundry_db_engine_mode             = var.db_engine_mode
  truefoundry_db_subnet_ids              = var.primary_subnet_ids
  truefoundry_db_ingress_security_group  = var.ingress_security_group
  truefoundry_db_ingress_cidr_blocks     = var.primary_ingress_cidr_blocks
  truefoundry_db_deletion_protection     = false
  truefoundry_db_skip_final_snapshot     = true
  truefoundry_db_backup_retention_period = 7

  # Aurora-specific (ignored when engine_mode = "rds")
  truefoundry_aurora_engine_version        = "17.4"
  truefoundry_aurora_instance_class        = "db.r6g.large"
  truefoundry_aurora_instance_count        = 1
  truefoundry_aurora_enable_global_cluster = var.enable_global_cluster

  truefoundry_aurora_secondary_config = var.enable_global_cluster ? {
    cluster_identifier         = "${var.cluster_name}-aurora-dr"
    vpc_id                     = var.dr_vpc_id
    subnet_ids                 = var.dr_subnet_ids
    ingress_cidr_blocks        = var.dr_ingress_cidr_blocks
    ingress_security_group_ids = var.dr_ingress_security_group_ids
  } : null

  # S3
  truefoundry_s3_enabled       = true
  truefoundry_s3_force_destroy = true

  # IAM
  truefoundry_iam_role_enabled = true
}

data "aws_caller_identity" "current" {}

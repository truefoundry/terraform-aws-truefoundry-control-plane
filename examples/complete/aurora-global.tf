module "aurora_global" {
  count  = var.db_engine_mode == "aurora" && var.enable_global_cluster ? 1 : 0
  source = "../../modules/aurora-global"

  providers = {
    aws           = aws
    aws.secondary = aws.secondary
  }

  aws_account_id                                  = data.aws_caller_identity.current.account_id
  cluster_name                                    = var.cluster_name
  secondary_cluster_name                          = "${var.cluster_name}-aurora-dr"
  truefoundry_aurora_global_cluster_identifier    = "${var.cluster_name}-aurora-global"
  vpc_id                                          = var.primary_vpc_id
  tags                                            = {}
  truefoundry_db_port                             = 5432
  truefoundry_db_engine_version                   = "17.5"
  truefoundry_db_deletion_protection              = false
  truefoundry_db_skip_final_snapshot              = true
  truefoundry_db_storage_encrypted                = true
  truefoundry_db_postgres_parameter_group_enabled = true
  truefoundry_db_aurora_cloudwatch_log_exports    = ["postgresql"]
  iam_database_authentication_enabled             = false

  truefoundry_aurora_secondary_config = {
    cluster_identifier         = "${var.cluster_name}-aurora-dr"
    vpc_id                     = var.dr_vpc_id
    subnet_ids                 = var.dr_subnet_ids
    ingress_cidr_blocks        = var.dr_ingress_cidr_blocks
    ingress_security_group_ids = var.dr_ingress_security_group_ids
  }

  truefoundry_aurora_vpc_peering_enabled = false

  depends_on = [module.control_plane]
}

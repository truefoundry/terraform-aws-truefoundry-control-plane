locals {

  truefoundry_unique_name = var.truefoundry_s3_enable_override ? var.truefoundry_s3_override_name : "${var.cluster_name}-truefoundry"

  truefoundry_db_unique_name = var.truefoundry_db_enable_override ? var.truefoundry_db_override_name : "${var.cluster_name}-db"

  mlfoundry_unique_name    = "${var.cluster_name}-${var.mlfoundry_name}"
  svcfoundry_unique_name   = "${var.cluster_name}-${var.svcfoundry_name}"
  mlmonitoring_unique_name = "${var.cluster_name}-${var.mlmonitoring_name}"

  truefoundry_db_port            = 5432
  truefoundry_db_master_username = "root"
  truefoundry_db_database_name   = "ctl"

  tags = merge(
    {
      "terraform-module" = "truefoundry-aws"
      "terraform"        = "true"
    },
    var.tags
  )
}
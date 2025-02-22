locals {

  truefoundry_unique_name         = var.truefoundry_s3_enable_override ? var.truefoundry_s3_override_name : "${var.cluster_name}-truefoundry"
  truefoundry_trimmed_unique_name = trimsuffix(substr(local.truefoundry_unique_name, 0, 37), "-")

  truefoundry_db_unique_name = var.truefoundry_db_enable_override ? var.truefoundry_db_override_name : "${var.cluster_name}-db"

  svcfoundry_unique_name = "${var.cluster_name}-${var.svcfoundry_k8s_service_account}"
  mlfoundry_unique_name  = "${var.cluster_name}-${var.mlfoundry_k8s_service_account}"

  truefoundry_db_port            = 5432
  truefoundry_db_master_username = "root"

  tags = merge(
    {
      "terraform-module" = "truefoundry-control-plane"
      "terraform"        = "true"
    },
    var.tags
  )
}

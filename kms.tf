# Kms key is used to encrypt the master user password for the RDS instance
resource "aws_kms_key" "truefoundry_db_master_user_secret_kms_key" {
  count               = var.truefoundry_db_enabled ? var.manage_master_user_password ? 1 : 0 : 0
  enable_key_rotation = true
  description         = "Truefoundry RDS Postgres Database encryption key"
  policy              = data.aws_iam_policy_document.truefoundry_db_master_user_secret_kms_policy[0].json
  tags                = local.tags
}

resource "aws_kms_alias" "truefoundry_db_master_user_secret_kms" {
  count         = var.truefoundry_db_enabled ? var.manage_master_user_password ? 1 : 0 : 0
  name          = "alias/${var.cluster_name}-db-kms"
  target_key_id = aws_kms_key.truefoundry_db_master_user_secret_kms_key[0].id
}

data "aws_iam_policy_document" "truefoundry_db_master_user_secret_kms_policy" {
  count   = var.truefoundry_db_enabled ? var.manage_master_user_password ? 1 : 0 : 0
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${var.aws_account_id}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }
}
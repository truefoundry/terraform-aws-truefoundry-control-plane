data "aws_iam_policy_document" "truefoundry_bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:HeadBucket",
    ]

    resources = concat(
      ["arn:aws:s3:::${local.truefoundry_unique_name}*"],
      var.truefoundry_artifact_buckets_will_read,
    )
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucketMultipartUploads",
      "s3:GetBucketTagging",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:PutObjectVersionTagging",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:AbortMultipartUpload",
      "s3:PutBucketTagging",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
      "s3:GetObjectVersion",
      "s3:ListBucket",
      "s3:DeleteObject",
    ]
    resources = [
      for bucket in concat(["arn:aws:s3:::${local.truefoundry_unique_name}*"], var.truefoundry_artifact_buckets_will_read) :
      "${bucket}/*"
    ]
  }
}

resource "aws_iam_policy" "truefoundry_bucket_policy" {
  count       = var.truefoundry_iam_role_enabled ? var.truefoundry_s3_enabled ? 1 : 0 : 0
  name_prefix = "${local.truefoundry_unique_name}-access-to-bucket"
  description = "IAM policy for TrueFoundry bucket"
  policy      = data.aws_iam_policy_document.truefoundry_bucket_policy.json
  tags        = local.tags
}

module "truefoundry_bucket" {
  count = var.truefoundry_s3_enabled ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.14.0"

  bucket        = var.truefoundry_s3_enable_override ? var.truefoundry_s3_override_name : null
  bucket_prefix = var.truefoundry_s3_enable_override ? null : trimsuffix(substr(local.truefoundry_unique_name, 0, 37), "-")

  force_destroy = var.truefoundry_s3_force_destroy

  tags = merge(
    {
      Name = var.truefoundry_s3_enable_override ? var.truefoundry_s3_override_name : trimsuffix(substr(local.truefoundry_unique_name, 0, 37), "-")
    },
    local.tags
  )


  # Bucket policies
  attach_policy                         = true
  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  # S3 bucket-level Public Access Block configuration
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # acl = "private" # "acl" conflicts with "grant" and "owner"

  versioning = {
    status     = true
    mfa_delete = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.truefoundry_s3_encryption_key_arn
        sse_algorithm     = var.truefoundry_s3_encryption_algorithm
      }
    }
  }

  intelligent_tiering = {
    general = {
      status = "Enabled"
      tiering = {
        ARCHIVE_ACCESS = {
          days = 90
        }
      }
    }
  }

  lifecycle_rule = [
    {
      id      = "abort-multipart-uploads-tfy-rule"
      status  = "Enabled"
      prefix  = ""
      enabled = true

      abort_incomplete_multipart_upload_days = 7
    }
  ]

  cors_rule = [
    {
      allowed_methods = ["GET", "POST", "PUT"]
      allowed_origins = var.truefoundry_s3_cors_origins
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
}

# terraform-aws-truefoundry-control-plane
This guide will help you to migrate your terraform code across versions. Keeping your terraform state to the latest version is always recommeneded

## Upgrade 0.3.x to 0.4.x
1. Ensure you have migrated to the latest version of `0.3.x` which is `0.3.10`
2. Run a plan with `0.4.0` by executing `terraform plan` or `terragrunt plan`
3. Run the following command to perform the resource moving
```shell
# running state move of IAM role
terragrunt state mv module.truefoundry_oidc_iam.aws_iam_role.this[0] module.truefoundry_oidc_iam[0].aws_iam_role.this[0]

# running a for loop to move the related policies
for i in {0..5}
do
echo "Doing this for resource $i"
terragrunt state mv module.truefoundry_oidc_iam.aws_iam_role_policy_attachment.custom[$i] module.truefoundry_oidc_iam[0].aws_iam_role_policy_attachment.custom[$i]
echo "Resource $i is moved"
done

terragrunt state mv module.truefoundry_bucket.aws_s3_bucket.this[0] module.truefoundry_bucket[0].aws_s3_bucket.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_cors_configuration.this[0] module.truefoundry_bucket[0].aws_s3_bucket_cors_configuration.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_intelligent_tiering_configuration.this module.truefoundry_bucket[0].aws_s3_bucket_intelligent_tiering_configuration.this
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_lifecycle_configuration.this[0] module.truefoundry_bucket[0].aws_s3_bucket_lifecycle_configuration.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_policy.this[0] module.truefoundry_bucket[0].aws_s3_bucket_policy.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_public_access_block.this[0] module.truefoundry_bucket[0].aws_s3_bucket_public_access_block.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_server_side_encryption_configuration.this[0] module.truefoundry_bucket[0].aws_s3_bucket_server_side_encryption_configuration.this[0]
terragrunt state mv module.truefoundry_bucket.aws_s3_bucket_versioning.this[0] module.truefoundry_bucket[0].aws_s3_bucket_versioning.this[0]
```
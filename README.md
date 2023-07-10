# terraform-aws-truefoundry-control-plane
Truefoundry AWS Control Plane Module

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mlfoundry_oidc_iam"></a> [mlfoundry\_oidc\_iam](#module\_mlfoundry\_oidc\_iam) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.27.0 |
| <a name="module_svcfoundry_oidc_iam"></a> [svcfoundry\_oidc\_iam](#module\_svcfoundry\_oidc\_iam) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.27.0 |
| <a name="module_truefoundry_bucket"></a> [truefoundry\_bucket](#module\_truefoundry\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.14.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.truefoundry_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.svcfoundry_access_to_multitenant_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.svcfoundry_access_to_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds-public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.truefoundry_db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_iam_policy.servicefoundry_ecr_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.svcfoundry_access_to_multitenant_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.svcfoundry_access_to_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | AWS Account Name | `string` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | EKS Cluster region | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name | `string` | n/a | yes |
| <a name="input_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#input\_cluster\_oidc\_issuer\_url) | The oidc url of the eks cluster | `string` | n/a | yes |
| <a name="input_mlfoundry_k8s_namespace"></a> [mlfoundry\_k8s\_namespace](#input\_mlfoundry\_k8s\_namespace) | The k8s mlfoundry namespace | `string` | n/a | yes |
| <a name="input_mlfoundry_k8s_service_account"></a> [mlfoundry\_k8s\_service\_account](#input\_mlfoundry\_k8s\_service\_account) | The k8s mlfoundry service account name | `string` | n/a | yes |
| <a name="input_mlfoundry_name"></a> [mlfoundry\_name](#input\_mlfoundry\_name) | Name of mlfoundry deployment | `string` | n/a | yes |
| <a name="input_mlmonitoring_k8s_namespace"></a> [mlmonitoring\_k8s\_namespace](#input\_mlmonitoring\_k8s\_namespace) | The k8s mlmonitoring namespace | `string` | n/a | yes |
| <a name="input_mlmonitoring_k8s_service_account"></a> [mlmonitoring\_k8s\_service\_account](#input\_mlmonitoring\_k8s\_service\_account) | The k8s mlmonitoring service account name | `string` | n/a | yes |
| <a name="input_mlmonitoring_name"></a> [mlmonitoring\_name](#input\_mlmonitoring\_name) | Name of mlmonitoring deployment | `string` | n/a | yes |
| <a name="input_svcfoundry_k8s_namespace"></a> [svcfoundry\_k8s\_namespace](#input\_svcfoundry\_k8s\_namespace) | The k8s svcfoundry namespace | `string` | n/a | yes |
| <a name="input_svcfoundry_k8s_service_account"></a> [svcfoundry\_k8s\_service\_account](#input\_svcfoundry\_k8s\_service\_account) | The k8s svcfoundry service account name | `string` | n/a | yes |
| <a name="input_svcfoundry_name"></a> [svcfoundry\_name](#input\_svcfoundry\_name) | Name of svcfoundry deployment | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS Tags common to all the resources created | `map(string)` | `{}` | no |
| <a name="input_truefoundry_artifact_buckets_will_read"></a> [truefoundry\_artifact\_buckets\_will\_read](#input\_truefoundry\_artifact\_buckets\_will\_read) | A list of bucket IDs mlfoundry will need read access to, in order to show the stored artifacts. It accepts any valid IAM resource, including ARNs with wildcards, so you can do something like arn:aws:s3:::bucket-prefix-* | `list(string)` | `[]` | no |
| <a name="input_truefoundry_db_allocated_storage"></a> [truefoundry\_db\_allocated\_storage](#input\_truefoundry\_db\_allocated\_storage) | Storage for RDS | `string` | n/a | yes |
| <a name="input_truefoundry_db_deletion_protection"></a> [truefoundry\_db\_deletion\_protection](#input\_truefoundry\_db\_deletion\_protection) | n/a | `bool` | `true` | no |
| <a name="input_truefoundry_db_enable_override"></a> [truefoundry\_db\_enable\_override](#input\_truefoundry\_db\_enable\_override) | Enable override for truefoundry db name. You must pass truefoundry\_db\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_db_engine_version"></a> [truefoundry\_db\_engine\_version](#input\_truefoundry\_db\_engine\_version) | Truefoundry DB Postgres version | `string` | `13.1` | no |
| <a name="input_truefoundry_db_ingress_security_group"></a> [truefoundry\_db\_ingress\_security\_group](#input\_truefoundry\_db\_ingress\_security\_group) | SG allowed to connect to the database | `string` | n/a | yes |
| <a name="input_truefoundry_db_instance_class"></a> [truefoundry\_db\_instance\_class](#input\_truefoundry\_db\_instance\_class) | Instance class for RDS | `string` | n/a | yes |
| <a name="input_truefoundry_db_override_name"></a> [truefoundry\_db\_override\_name](#input\_truefoundry\_db\_override\_name) | Override name for truefoundry db. truefoundry\_db\_enable\_override must be set true | `string` | `""` | no |
| <a name="input_truefoundry_db_publicly_accessible"></a> [truefoundry\_db\_publicly\_accessible](#input\_truefoundry\_db\_publicly\_accessible) | Make database publicly accessible. Subnets and SG must match | `string` | `false` | no |
| <a name="input_truefoundry_db_skip_final_snapshot"></a> [truefoundry\_db\_skip\_final\_snapshot](#input\_truefoundry\_db\_skip\_final\_snapshot) | n/a | `bool` | `false` | no |
| <a name="input_truefoundry_db_storage_encrypted"></a> [truefoundry\_db\_storage\_encrypted](#input\_truefoundry\_db\_storage\_encrypted) | n/a | `bool` | `true` | no |
| <a name="input_truefoundry_db_storage_iops"></a> [truefoundry\_db\_storage\_iops](#input\_truefoundry\_db\_storage\_iops) | Provisioned IOPS for the db | `number` | n/a | yes |
| <a name="input_truefoundry_db_storage_type"></a> [truefoundry\_db\_storage\_type](#input\_truefoundry\_db\_storage\_type) | Storage type for truefoundry db | `string` | n/a | yes |
| <a name="input_truefoundry_db_subnet_ids"></a> [truefoundry\_db\_subnet\_ids](#input\_truefoundry\_db\_subnet\_ids) | List of subnets where the RDS database will be deployed | `list(string)` | n/a | yes |
| <a name="input_truefoundry_s3_cors_origins"></a> [truefoundry\_s3\_cors\_origins](#input\_truefoundry\_s3\_cors\_origins) | List of CORS origins for Mlfoundry bucket | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_truefoundry_s3_enable_override"></a> [truefoundry\_s3\_enable\_override](#input\_truefoundry\_s3\_enable\_override) | Enable override for s3 bucket name. You must pass truefoundry\_s3\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_s3_encryption_algorithm"></a> [truefoundry\_s3\_encryption\_algorithm](#input\_truefoundry\_s3\_encryption\_algorithm) | Algorithm used for encrypting the default bucket. | `string` | `"AES256"` | no |
| <a name="input_truefoundry_s3_encryption_key_arn"></a> [truefoundry\_s3\_encryption\_key\_arn](#input\_truefoundry\_s3\_encryption\_key\_arn) | ARN of the key used to encrypt the bucket. Only needed if you set aws:kms as encryption algorithm. | `string` | `null` | no |
| <a name="input_truefoundry_s3_force_destroy"></a> [truefoundry\_s3\_force\_destroy](#input\_truefoundry\_s3\_force\_destroy) | Force destroy for mlfoundry s3 bucket | `bool` | `false` | no |
| <a name="input_truefoundry_s3_override_name"></a> [truefoundry\_s3\_override\_name](#input\_truefoundry\_s3\_override\_name) | Override name for s3 bucket. truefoundry\_s3\_enable\_override must be set true | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS VPC to deploy Truefoundry rds | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_mlfoundry_iam_role_arn"></a> [mlfoundry\_iam\_role\_arn](#output\_mlfoundry\_iam\_role\_arn) | n/a |
| <a name="output_svcfoundry_iam_role_arn"></a> [svcfoundry\_iam\_role\_arn](#output\_svcfoundry\_iam\_role\_arn) | n/a |
| <a name="output_truefoundry_bucket_id"></a> [truefoundry\_bucket\_id](#output\_truefoundry\_bucket\_id) | n/a |
| <a name="output_truefoundry_db_address"></a> [truefoundry\_db\_address](#output\_truefoundry\_db\_address) | n/a |
| <a name="output_truefoundry_db_database_name"></a> [truefoundry\_db\_database\_name](#output\_truefoundry\_db\_database\_name) | n/a |
| <a name="output_truefoundry_db_endpoint"></a> [truefoundry\_db\_endpoint](#output\_truefoundry\_db\_endpoint) | n/a |
| <a name="output_truefoundry_db_engine"></a> [truefoundry\_db\_engine](#output\_truefoundry\_db\_engine) | n/a |
| <a name="output_truefoundry_db_id"></a> [truefoundry\_db\_id](#output\_truefoundry\_db\_id) | n/a |
| <a name="output_truefoundry_db_password"></a> [truefoundry\_db\_password](#output\_truefoundry\_db\_password) | n/a |
| <a name="output_truefoundry_db_port"></a> [truefoundry\_db\_port](#output\_truefoundry\_db\_port) | n/a |
| <a name="output_truefoundry_db_username"></a> [truefoundry\_db\_username](#output\_truefoundry\_db\_username) | n/a |
<!-- END_TF_DOCS -->
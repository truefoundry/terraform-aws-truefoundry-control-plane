# terraform-aws-truefoundry-control-plane
Truefoundry AWS Control Plane Module

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.63.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.63.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_truefoundry_bucket"></a> [truefoundry\_bucket](#module\_truefoundry\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.14.0 |
| <a name="module_truefoundry_oidc_iam"></a> [truefoundry\_oidc\_iam](#module\_truefoundry\_oidc\_iam) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.39.1 |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.truefoundry_db](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.rds](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.svcfoundry_access_to_ecr](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.svcfoundry_access_to_multitenant_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.svcfoundry_access_to_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_assume_role_all](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_db_iam_auth_policy](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/iam_policy) | resource |
| [aws_kms_alias.truefoundry_db_master_user_secret_kms](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/kms_alias) | resource |
| [aws_kms_key.truefoundry_db_master_user_secret_kms_key](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret_rotation.turefoundry_db_secret_rotation](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/security_group) | resource |
| [aws_security_group.rds-public](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/resources/security_group) | resource |
| [random_password.truefoundry_db_password](https://registry.terraform.io/providers/hashicorp/random/3.6.2/docs/resources/password) | resource |
| [aws_iam_policy_document.svcfoundry_access_to_ecr](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.svcfoundry_access_to_multitenant_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.svcfoundry_access_to_ssm](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_assume_role_all](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_db_iam_auth_policy_document](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_db_master_user_secret_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/5.63.0/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_name"></a> [account\_name](#input\_account\_name) | AWS Account Name | `string` | n/a | yes |
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | EKS Cluster region | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name | `string` | n/a | yes |
| <a name="input_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#input\_cluster\_oidc\_issuer\_url) | The oidc url of the eks cluster | `string` | n/a | yes |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Enable IAM database authentication | `bool` | `false` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Enable master user password management. If set to true master user management is done by RDS in secrets manager, if false a random password is generated | `bool` | `false` | no |
| <a name="input_manage_master_user_password_rotation"></a> [manage\_master\_user\_password\_rotation](#input\_manage\_master\_user\_password\_rotation) | Enable master user password rotation | `bool` | `false` | no |
| <a name="input_master_user_password_rotate_immediately"></a> [master\_user\_password\_rotate\_immediately](#input\_master\_user\_password\_rotate\_immediately) | Rotate master user password immediately | `bool` | `false` | no |
| <a name="input_master_user_password_rotation_automatically_after_days"></a> [master\_user\_password\_rotation\_automatically\_after\_days](#input\_master\_user\_password\_rotation\_automatically\_after\_days) | Rotate master user password automatically after days | `number` | `90` | no |
| <a name="input_master_user_password_rotation_duration"></a> [master\_user\_password\_rotation\_duration](#input\_master\_user\_password\_rotation\_duration) | Master user password rotation duration | `string` | `"3h"` | no |
| <a name="input_mlfoundry_k8s_namespace"></a> [mlfoundry\_k8s\_namespace](#input\_mlfoundry\_k8s\_namespace) | The k8s mlfoundry namespace | `string` | n/a | yes |
| <a name="input_mlfoundry_k8s_service_account"></a> [mlfoundry\_k8s\_service\_account](#input\_mlfoundry\_k8s\_service\_account) | The k8s mlfoundry service account name | `string` | n/a | yes |
| <a name="input_mlfoundry_name"></a> [mlfoundry\_name](#input\_mlfoundry\_name) | Name of mlfoundry deployment | `string` | n/a | yes |
| <a name="input_svcfoundry_k8s_namespace"></a> [svcfoundry\_k8s\_namespace](#input\_svcfoundry\_k8s\_namespace) | The k8s svcfoundry namespace | `string` | n/a | yes |
| <a name="input_svcfoundry_k8s_service_account"></a> [svcfoundry\_k8s\_service\_account](#input\_svcfoundry\_k8s\_service\_account) | The k8s svcfoundry service account name | `string` | n/a | yes |
| <a name="input_svcfoundry_name"></a> [svcfoundry\_name](#input\_svcfoundry\_name) | Name of svcfoundry deployment | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS Tags common to all the resources created | `map(string)` | `{}` | no |
| <a name="input_tfy_workflow_admin_k8s_namespace"></a> [tfy\_workflow\_admin\_k8s\_namespace](#input\_tfy\_workflow\_admin\_k8s\_namespace) | The k8s tfy workflow admin namespace | `string` | n/a | yes |
| <a name="input_tfy_workflow_admin_k8s_service_account"></a> [tfy\_workflow\_admin\_k8s\_service\_account](#input\_tfy\_workflow\_admin\_k8s\_service\_account) | The k8s tfy workflow admin service account name | `string` | n/a | yes |
| <a name="input_tfy_workflow_admin_name"></a> [tfy\_workflow\_admin\_name](#input\_tfy\_workflow\_admin\_name) | Name of tfy workflow admin deployment | `string` | n/a | yes |
| <a name="input_truefoundry_artifact_buckets_will_read"></a> [truefoundry\_artifact\_buckets\_will\_read](#input\_truefoundry\_artifact\_buckets\_will\_read) | A list of bucket IDs mlfoundry will need read access to, in order to show the stored artifacts. It accepts any valid IAM resource, including ARNs with wildcards, so you can do something like arn:aws:s3:::bucket-prefix-* | `list(string)` | `[]` | no |
| <a name="input_truefoundry_db_allocated_storage"></a> [truefoundry\_db\_allocated\_storage](#input\_truefoundry\_db\_allocated\_storage) | Storage for RDS. Minimum storage allowed for gp3 volumes is 20GB | `string` | `"20"` | no |
| <a name="input_truefoundry_db_backup_retention_period"></a> [truefoundry\_db\_backup\_retention\_period](#input\_truefoundry\_db\_backup\_retention\_period) | Backup retention period for RDS | `number` | `14` | no |
| <a name="input_truefoundry_db_deletion_protection"></a> [truefoundry\_db\_deletion\_protection](#input\_truefoundry\_db\_deletion\_protection) | n/a | `bool` | `true` | no |
| <a name="input_truefoundry_db_enable_insights"></a> [truefoundry\_db\_enable\_insights](#input\_truefoundry\_db\_enable\_insights) | Enable insights to truefoundry db | `bool` | `false` | no |
| <a name="input_truefoundry_db_enable_override"></a> [truefoundry\_db\_enable\_override](#input\_truefoundry\_db\_enable\_override) | Enable override for truefoundry db name. You must pass truefoundry\_db\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_db_enabled"></a> [truefoundry\_db\_enabled](#input\_truefoundry\_db\_enabled) | variable to enable/disable truefoundry db creation | `bool` | `true` | no |
| <a name="input_truefoundry_db_engine_version"></a> [truefoundry\_db\_engine\_version](#input\_truefoundry\_db\_engine\_version) | Truefoundry DB Postgres version | `string` | `"13.14"` | no |
| <a name="input_truefoundry_db_ingress_cidr_blocks"></a> [truefoundry\_db\_ingress\_cidr\_blocks](#input\_truefoundry\_db\_ingress\_cidr\_blocks) | CIDR blocks allowed to connect to the database | `list(string)` | n/a | yes |
| <a name="input_truefoundry_db_ingress_security_group"></a> [truefoundry\_db\_ingress\_security\_group](#input\_truefoundry\_db\_ingress\_security\_group) | SG allowed to connect to the database | `string` | n/a | yes |
| <a name="input_truefoundry_db_instance_class"></a> [truefoundry\_db\_instance\_class](#input\_truefoundry\_db\_instance\_class) | Instance class for RDS | `string` | n/a | yes |
| <a name="input_truefoundry_db_max_allocated_storage"></a> [truefoundry\_db\_max\_allocated\_storage](#input\_truefoundry\_db\_max\_allocated\_storage) | Max allowed storage for RDS when autoscaling is enabled | `string` | n/a | yes |
| <a name="input_truefoundry_db_multiple_az"></a> [truefoundry\_db\_multiple\_az](#input\_truefoundry\_db\_multiple\_az) | Enable Multi-az (standby) instances for RDS instances | `bool` | `false` | no |
| <a name="input_truefoundry_db_override_name"></a> [truefoundry\_db\_override\_name](#input\_truefoundry\_db\_override\_name) | Override name for truefoundry db. truefoundry\_db\_enable\_override must be set true | `string` | `""` | no |
| <a name="input_truefoundry_db_publicly_accessible"></a> [truefoundry\_db\_publicly\_accessible](#input\_truefoundry\_db\_publicly\_accessible) | Make database publicly accessible. Subnets and SG must match | `string` | `false` | no |
| <a name="input_truefoundry_db_skip_final_snapshot"></a> [truefoundry\_db\_skip\_final\_snapshot](#input\_truefoundry\_db\_skip\_final\_snapshot) | n/a | `bool` | `false` | no |
| <a name="input_truefoundry_db_storage_encrypted"></a> [truefoundry\_db\_storage\_encrypted](#input\_truefoundry\_db\_storage\_encrypted) | n/a | `bool` | `true` | no |
| <a name="input_truefoundry_db_storage_iops"></a> [truefoundry\_db\_storage\_iops](#input\_truefoundry\_db\_storage\_iops) | Provisioned IOPS for the db | `number` | n/a | yes |
| <a name="input_truefoundry_db_storage_type"></a> [truefoundry\_db\_storage\_type](#input\_truefoundry\_db\_storage\_type) | Storage type for truefoundry db | `string` | `"gp3"` | no |
| <a name="input_truefoundry_db_subnet_ids"></a> [truefoundry\_db\_subnet\_ids](#input\_truefoundry\_db\_subnet\_ids) | List of subnets where the RDS database will be deployed | `list(string)` | n/a | yes |
| <a name="input_truefoundry_iam_role_enabled"></a> [truefoundry\_iam\_role\_enabled](#input\_truefoundry\_iam\_role\_enabled) | variable to enable/disable truefoundry iam role creation | `bool` | `true` | no |
| <a name="input_truefoundry_s3_cors_origins"></a> [truefoundry\_s3\_cors\_origins](#input\_truefoundry\_s3\_cors\_origins) | List of CORS origins for Mlfoundry bucket | `list(string)` | <pre>[<br>  "*"<br>]</pre> | no |
| <a name="input_truefoundry_s3_enable_override"></a> [truefoundry\_s3\_enable\_override](#input\_truefoundry\_s3\_enable\_override) | Enable override for s3 bucket name. You must pass truefoundry\_s3\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_s3_enabled"></a> [truefoundry\_s3\_enabled](#input\_truefoundry\_s3\_enabled) | variable to enable/disable truefoundry s3 bucket creation | `bool` | `true` | no |
| <a name="input_truefoundry_s3_encryption_algorithm"></a> [truefoundry\_s3\_encryption\_algorithm](#input\_truefoundry\_s3\_encryption\_algorithm) | Algorithm used for encrypting the default bucket. | `string` | `"AES256"` | no |
| <a name="input_truefoundry_s3_encryption_key_arn"></a> [truefoundry\_s3\_encryption\_key\_arn](#input\_truefoundry\_s3\_encryption\_key\_arn) | ARN of the key used to encrypt the bucket. Only needed if you set aws:kms as encryption algorithm. | `string` | `null` | no |
| <a name="input_truefoundry_s3_force_destroy"></a> [truefoundry\_s3\_force\_destroy](#input\_truefoundry\_s3\_force\_destroy) | Force destroy for mlfoundry s3 bucket | `bool` | `false` | no |
| <a name="input_truefoundry_s3_override_name"></a> [truefoundry\_s3\_override\_name](#input\_truefoundry\_s3\_override\_name) | Override name for s3 bucket. truefoundry\_s3\_enable\_override must be set true | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | AWS VPC to deploy Truefoundry rds | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_truefoundry_bucket_id"></a> [truefoundry\_bucket\_id](#output\_truefoundry\_bucket\_id) | n/a |
| <a name="output_truefoundry_db_address"></a> [truefoundry\_db\_address](#output\_truefoundry\_db\_address) | n/a |
| <a name="output_truefoundry_db_database_name"></a> [truefoundry\_db\_database\_name](#output\_truefoundry\_db\_database\_name) | n/a |
| <a name="output_truefoundry_db_endpoint"></a> [truefoundry\_db\_endpoint](#output\_truefoundry\_db\_endpoint) | n/a |
| <a name="output_truefoundry_db_engine"></a> [truefoundry\_db\_engine](#output\_truefoundry\_db\_engine) | n/a |
| <a name="output_truefoundry_db_id"></a> [truefoundry\_db\_id](#output\_truefoundry\_db\_id) | n/a |
| <a name="output_truefoundry_db_password"></a> [truefoundry\_db\_password](#output\_truefoundry\_db\_password) | n/a |
| <a name="output_truefoundry_db_port"></a> [truefoundry\_db\_port](#output\_truefoundry\_db\_port) | n/a |
| <a name="output_truefoundry_db_username"></a> [truefoundry\_db\_username](#output\_truefoundry\_db\_username) | n/a |
| <a name="output_truefoundry_iam_role_arn"></a> [truefoundry\_iam\_role\_arn](#output\_truefoundry\_iam\_role\_arn) | n/a |
<!-- END_TF_DOCS -->
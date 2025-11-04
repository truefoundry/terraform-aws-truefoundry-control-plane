# terraform-aws-truefoundry-control-plane
Truefoundry AWS Control Plane Module

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.57 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.57 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.6 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_truefoundry_bucket"></a> [truefoundry\_bucket](#module\_truefoundry\_bucket) | terraform-aws-modules/s3-bucket/aws | 3.14.0 |
| <a name="module_truefoundry_oidc_iam"></a> [truefoundry\_oidc\_iam](#module\_truefoundry\_oidc\_iam) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.39.1 |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance.truefoundry_db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.truefoundry_db_parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_policy.svcfoundry_access_to_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.svcfoundry_access_to_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.svcfoundry_access_to_multitenant_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_assume_role_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.truefoundry_db_iam_auth_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.truefoundry_db_monitoring_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.truefoundry_db_monitoring_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.truefoundry_db_master_user_secret_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.truefoundry_db_master_user_secret_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret_rotation.turefoundry_db_secret_rotation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.rds-public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.truefoundry_db_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_iam_policy_document.svcfoundry_access_to_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.svcfoundry_access_to_eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.svcfoundry_access_to_multitenant_ssm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_assume_role_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_db_iam_auth_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_db_master_user_secret_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.truefoundry_db_monitoring_role_trust_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_account_id"></a> [aws\_account\_id](#input\_aws\_account\_id) | AWS Account ID | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | EKS Cluster region | `string` | n/a | yes |
| <a name="input_blob_storage_extra_tags"></a> [blob\_storage\_extra\_tags](#input\_blob\_storage\_extra\_tags) | Extra tags for the s3 bucket | `map(string)` | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Cluster name | `string` | n/a | yes |
| <a name="input_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#input\_cluster\_oidc\_issuer\_url) | The oidc url of the eks cluster | `string` | n/a | yes |
| <a name="input_disable_default_tags"></a> [disable\_default\_tags](#input\_disable\_default\_tags) | Disable default tags for the resources created | `bool` | `false` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Enable IAM database authentication | `bool` | `false` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Enable master user password management. If set to true master user management is done by RDS in secrets manager, if false a random password is generated | `bool` | `false` | no |
| <a name="input_manage_master_user_password_rotation"></a> [manage\_master\_user\_password\_rotation](#input\_manage\_master\_user\_password\_rotation) | Enable master user password rotation | `bool` | `false` | no |
| <a name="input_master_user_password_rotate_immediately"></a> [master\_user\_password\_rotate\_immediately](#input\_master\_user\_password\_rotate\_immediately) | Rotate master user password immediately | `bool` | `false` | no |
| <a name="input_master_user_password_rotation_automatically_after_days"></a> [master\_user\_password\_rotation\_automatically\_after\_days](#input\_master\_user\_password\_rotation\_automatically\_after\_days) | Rotate master user password automatically after days | `number` | `90` | no |
| <a name="input_master_user_password_rotation_duration"></a> [master\_user\_password\_rotation\_duration](#input\_master\_user\_password\_rotation\_duration) | Master user password rotation duration | `string` | `"3h"` | no |
| <a name="input_mlfoundry_k8s_namespace"></a> [mlfoundry\_k8s\_namespace](#input\_mlfoundry\_k8s\_namespace) | The k8s mlfoundry namespace | `string` | `"truefoundry"` | no |
| <a name="input_mlfoundry_k8s_service_account"></a> [mlfoundry\_k8s\_service\_account](#input\_mlfoundry\_k8s\_service\_account) | The k8s mlfoundry service account name | `string` | `"mlfoundry-server"` | no |
| <a name="input_svcfoundry_k8s_namespace"></a> [svcfoundry\_k8s\_namespace](#input\_svcfoundry\_k8s\_namespace) | The k8s svcfoundry namespace | `string` | `"truefoundry"` | no |
| <a name="input_svcfoundry_k8s_service_account"></a> [svcfoundry\_k8s\_service\_account](#input\_svcfoundry\_k8s\_service\_account) | The k8s svcfoundry service account name | `string` | `"servicefoundry-server"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS Tags common to all the resources created | `map(string)` | `{}` | no |
| <a name="input_tfy_llm_gateway_k8s_namespace"></a> [tfy\_llm\_gateway\_k8s\_namespace](#input\_tfy\_llm\_gateway\_k8s\_namespace) | Truefoundry k8s llm-gateway service account name | `string` | `"truefoundry"` | no |
| <a name="input_tfy_llm_gateway_k8s_service_account"></a> [tfy\_llm\_gateway\_k8s\_service\_account](#input\_tfy\_llm\_gateway\_k8s\_service\_account) | Truefoundry k8s namespace | `string` | `"tfy-llm-gateway"` | no |
| <a name="input_tfy_workflow_admin_k8s_namespace"></a> [tfy\_workflow\_admin\_k8s\_namespace](#input\_tfy\_workflow\_admin\_k8s\_namespace) | The k8s tfy workflow admin namespace | `string` | `"truefoundry"` | no |
| <a name="input_tfy_workflow_admin_k8s_service_account"></a> [tfy\_workflow\_admin\_k8s\_service\_account](#input\_tfy\_workflow\_admin\_k8s\_service\_account) | The k8s tfy workflow admin service account name | `string` | `"tfy-workflow-admin"` | no |
| <a name="input_truefoundry_artifact_buckets_will_read"></a> [truefoundry\_artifact\_buckets\_will\_read](#input\_truefoundry\_artifact\_buckets\_will\_read) | A list of bucket IDs mlfoundry will need read access to, in order to show the stored artifacts. It accepts any valid IAM resource, including ARNs with wildcards, so you can do something like arn:aws:s3:::bucket-prefix-* | `list(string)` | `[]` | no |
| <a name="input_truefoundry_cloudwatch_log_exports"></a> [truefoundry\_cloudwatch\_log\_exports](#input\_truefoundry\_cloudwatch\_log\_exports) | Set of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported | `list(string)` | <pre>[<br/>  "postgresql",<br/>  "upgrade"<br/>]</pre> | no |
| <a name="input_truefoundry_db_additional_security_group_ids"></a> [truefoundry\_db\_additional\_security\_group\_ids](#input\_truefoundry\_db\_additional\_security\_group\_ids) | Additional security group IDs to add to the database | `list(string)` | `[]` | no |
| <a name="input_truefoundry_db_allocated_storage"></a> [truefoundry\_db\_allocated\_storage](#input\_truefoundry\_db\_allocated\_storage) | Storage for RDS. Minimum storage allowed for gp3 volumes is 20GB | `string` | `"20"` | no |
| <a name="input_truefoundry_db_allow_major_version_upgrade"></a> [truefoundry\_db\_allow\_major\_version\_upgrade](#input\_truefoundry\_db\_allow\_major\_version\_upgrade) | Allow major version upgrade. This should be set to true if you want to upgrade the db version | `bool` | `false` | no |
| <a name="input_truefoundry_db_backup_retention_period"></a> [truefoundry\_db\_backup\_retention\_period](#input\_truefoundry\_db\_backup\_retention\_period) | Backup retention period for RDS | `number` | `14` | no |
| <a name="input_truefoundry_db_database_name"></a> [truefoundry\_db\_database\_name](#input\_truefoundry\_db\_database\_name) | Name of the database in DB | `string` | `"ctl"` | no |
| <a name="input_truefoundry_db_deletion_protection"></a> [truefoundry\_db\_deletion\_protection](#input\_truefoundry\_db\_deletion\_protection) | n/a | `bool` | `true` | no |
| <a name="input_truefoundry_db_enable_insights"></a> [truefoundry\_db\_enable\_insights](#input\_truefoundry\_db\_enable\_insights) | Enable insights to truefoundry db | `bool` | `false` | no |
| <a name="input_truefoundry_db_enable_monitoring"></a> [truefoundry\_db\_enable\_monitoring](#input\_truefoundry\_db\_enable\_monitoring) | Enable enhanced monitoring for the RDS DB instance.<br/><br/>  This will create an IAM role and attach the necessary policies to the DB instance. If you want to use an existing IAM role, set `truefoundry_db_monitoring_role_arn`<br/><br/>  Default collection interval is 5 seconds. Override with `truefoundry_db_monitoring_interval`.<br/><br/>  https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.Enabling.html | `bool` | `false` | no |
| <a name="input_truefoundry_db_enable_override"></a> [truefoundry\_db\_enable\_override](#input\_truefoundry\_db\_enable\_override) | Enable override for truefoundry db name. You must pass truefoundry\_db\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_db_enabled"></a> [truefoundry\_db\_enabled](#input\_truefoundry\_db\_enabled) | variable to enable/disable truefoundry db creation | `bool` | `true` | no |
| <a name="input_truefoundry_db_engine_version"></a> [truefoundry\_db\_engine\_version](#input\_truefoundry\_db\_engine\_version) | Truefoundry DB Postgres version | `string` | `"17.5"` | no |
| <a name="input_truefoundry_db_ingress_cidr_blocks"></a> [truefoundry\_db\_ingress\_cidr\_blocks](#input\_truefoundry\_db\_ingress\_cidr\_blocks) | CIDR blocks allowed to connect to the database | `list(string)` | `[]` | no |
| <a name="input_truefoundry_db_ingress_security_group"></a> [truefoundry\_db\_ingress\_security\_group](#input\_truefoundry\_db\_ingress\_security\_group) | SG allowed to connect to the database | `string` | `""` | no |
| <a name="input_truefoundry_db_instance_class"></a> [truefoundry\_db\_instance\_class](#input\_truefoundry\_db\_instance\_class) | Instance class for RDS | `string` | `"db.t3.medium"` | no |
| <a name="input_truefoundry_db_max_allocated_storage"></a> [truefoundry\_db\_max\_allocated\_storage](#input\_truefoundry\_db\_max\_allocated\_storage) | Max allowed storage for RDS when autoscaling is enabled | `string` | `"30"` | no |
| <a name="input_truefoundry_db_monitoring_interval"></a> [truefoundry\_db\_monitoring\_interval](#input\_truefoundry\_db\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance | `number` | `5` | no |
| <a name="input_truefoundry_db_monitoring_role_arn"></a> [truefoundry\_db\_monitoring\_role\_arn](#input\_truefoundry\_db\_monitoring\_role\_arn) | Existing IAM role ARN for DB monitoring.<br/><br/>  https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.Enabling.html#USER_Monitoring.OS.Enabling.Prerequisites | `string` | `""` | no |
| <a name="input_truefoundry_db_multiple_az"></a> [truefoundry\_db\_multiple\_az](#input\_truefoundry\_db\_multiple\_az) | Enable Multi-az (standby) instances for RDS instances | `bool` | `false` | no |
| <a name="input_truefoundry_db_override_name"></a> [truefoundry\_db\_override\_name](#input\_truefoundry\_db\_override\_name) | Override name for truefoundry db.This is the name of the RDS resources in AWS . truefoundry\_db\_enable\_override must be set true | `string` | `""` | no |
| <a name="input_truefoundry_db_override_special_characters"></a> [truefoundry\_db\_override\_special\_characters](#input\_truefoundry\_db\_override\_special\_characters) | Override special characters for the database name | `string` | `"#%&*()-_=+[]{}<>:"` | no |
| <a name="input_truefoundry_db_postgres_parameter_group_override_enabled"></a> [truefoundry\_db\_postgres\_parameter\_group\_override\_enabled](#input\_truefoundry\_db\_postgres\_parameter\_group\_override\_enabled) | Enable override for postgres parameter group. You must pass truefoundry\_db\_postgres\_parameter\_group\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_db_postgres_parameter_group_override_name"></a> [truefoundry\_db\_postgres\_parameter\_group\_override\_name](#input\_truefoundry\_db\_postgres\_parameter\_group\_override\_name) | Override name for postgres parameter group. truefoundry\_db\_postgres\_parameter\_group\_override\_enabled must be set true | `string` | `""` | no |
| <a name="input_truefoundry_db_publicly_accessible"></a> [truefoundry\_db\_publicly\_accessible](#input\_truefoundry\_db\_publicly\_accessible) | Make database publicly accessible. Subnets and SG must match | `string` | `false` | no |
| <a name="input_truefoundry_db_skip_final_snapshot"></a> [truefoundry\_db\_skip\_final\_snapshot](#input\_truefoundry\_db\_skip\_final\_snapshot) | n/a | `bool` | `false` | no |
| <a name="input_truefoundry_db_storage_encrypted"></a> [truefoundry\_db\_storage\_encrypted](#input\_truefoundry\_db\_storage\_encrypted) | n/a | `bool` | `true` | no |
| <a name="input_truefoundry_db_storage_iops"></a> [truefoundry\_db\_storage\_iops](#input\_truefoundry\_db\_storage\_iops) | Provisioned IOPS for the db | `number` | `0` | no |
| <a name="input_truefoundry_db_storage_type"></a> [truefoundry\_db\_storage\_type](#input\_truefoundry\_db\_storage\_type) | Storage type for truefoundry db | `string` | `"gp3"` | no |
| <a name="input_truefoundry_db_subnet_ids"></a> [truefoundry\_db\_subnet\_ids](#input\_truefoundry\_db\_subnet\_ids) | List of subnets where the RDS database will be deployed | `list(string)` | `[]` | no |
| <a name="input_truefoundry_iam_role_additional_oidc_subjects"></a> [truefoundry\_iam\_role\_additional\_oidc\_subjects](#input\_truefoundry\_iam\_role\_additional\_oidc\_subjects) | List of fully qualifies oidc subjects that can assume the truefoundry IAM role | `list(string)` | `[]` | no |
| <a name="input_truefoundry_iam_role_additional_policies_arn"></a> [truefoundry\_iam\_role\_additional\_policies\_arn](#input\_truefoundry\_iam\_role\_additional\_policies\_arn) | List of ARN of policies that you want to attach to the | `list(string)` | `[]` | no |
| <a name="input_truefoundry_iam_role_enable_override"></a> [truefoundry\_iam\_role\_enable\_override](#input\_truefoundry\_iam\_role\_enable\_override) | Enable overriding the truefoundry IAM role name. You need to pass truefoundry\_iam\_role\_override\_name to pass the role name | `bool` | `false` | no |
| <a name="input_truefoundry_iam_role_enabled"></a> [truefoundry\_iam\_role\_enabled](#input\_truefoundry\_iam\_role\_enabled) | variable to enable/disable truefoundry iam role creation | `bool` | `true` | no |
| <a name="input_truefoundry_iam_role_override_name"></a> [truefoundry\_iam\_role\_override\_name](#input\_truefoundry\_iam\_role\_override\_name) | Truefoundry IAM role name | `string` | `""` | no |
| <a name="input_truefoundry_iam_role_permission_boundary_arn"></a> [truefoundry\_iam\_role\_permission\_boundary\_arn](#input\_truefoundry\_iam\_role\_permission\_boundary\_arn) | ARN of the permission boundary to attach to the truefoundry IAM role | `string` | `null` | no |
| <a name="input_truefoundry_iam_role_policy_prefix_override_enabled"></a> [truefoundry\_iam\_role\_policy\_prefix\_override\_enabled](#input\_truefoundry\_iam\_role\_policy\_prefix\_override\_enabled) | Enable overriding the truefoundry IAM role policy prefix. You need to pass truefoundry\_iam\_role\_policy\_prefix\_override\_name to pass the policy prefix | `bool` | `false` | no |
| <a name="input_truefoundry_iam_role_policy_prefix_override_name"></a> [truefoundry\_iam\_role\_policy\_prefix\_override\_name](#input\_truefoundry\_iam\_role\_policy\_prefix\_override\_name) | Truefoundry IAM role policy prefix. This is the prefix for the policies that will be attached to the truefoundry IAM role | `string` | `""` | no |
| <a name="input_truefoundry_k8s_namespace"></a> [truefoundry\_k8s\_namespace](#input\_truefoundry\_k8s\_namespace) | Truefoundry k8s namespace | `string` | `"truefoundry"` | no |
| <a name="input_truefoundry_s3_attach_deny_insecure_transport_policy"></a> [truefoundry\_s3\_attach\_deny\_insecure\_transport\_policy](#input\_truefoundry\_s3\_attach\_deny\_insecure\_transport\_policy) | Attach deny insecure transport policy for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_attach_policy"></a> [truefoundry\_s3\_attach\_policy](#input\_truefoundry\_s3\_attach\_policy) | Attach policy for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_attach_public_policy"></a> [truefoundry\_s3\_attach\_public\_policy](#input\_truefoundry\_s3\_attach\_public\_policy) | Attach public policy for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_attach_require_latest_tls_policy"></a> [truefoundry\_s3\_attach\_require\_latest\_tls\_policy](#input\_truefoundry\_s3\_attach\_require\_latest\_tls\_policy) | Attach require latest TLS policy for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_block_public_acls"></a> [truefoundry\_s3\_block\_public\_acls](#input\_truefoundry\_s3\_block\_public\_acls) | Block public ACLs for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_block_public_policy"></a> [truefoundry\_s3\_block\_public\_policy](#input\_truefoundry\_s3\_block\_public\_policy) | Block public policy for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_cors_origins"></a> [truefoundry\_s3\_cors\_origins](#input\_truefoundry\_s3\_cors\_origins) | List of CORS origins for Mlfoundry bucket | `list(string)` | <pre>[<br/>  "*"<br/>]</pre> | no |
| <a name="input_truefoundry_s3_enable_override"></a> [truefoundry\_s3\_enable\_override](#input\_truefoundry\_s3\_enable\_override) | Enable override for s3 bucket name. You must pass truefoundry\_s3\_override\_name | `bool` | `false` | no |
| <a name="input_truefoundry_s3_enabled"></a> [truefoundry\_s3\_enabled](#input\_truefoundry\_s3\_enabled) | variable to enable/disable truefoundry s3 bucket creation | `bool` | `true` | no |
| <a name="input_truefoundry_s3_encryption_algorithm"></a> [truefoundry\_s3\_encryption\_algorithm](#input\_truefoundry\_s3\_encryption\_algorithm) | Algorithm used for encrypting the default bucket. | `string` | `"AES256"` | no |
| <a name="input_truefoundry_s3_encryption_key_arn"></a> [truefoundry\_s3\_encryption\_key\_arn](#input\_truefoundry\_s3\_encryption\_key\_arn) | ARN of the key used to encrypt the bucket. Only needed if you set aws:kms as encryption algorithm. | `string` | `null` | no |
| <a name="input_truefoundry_s3_force_destroy"></a> [truefoundry\_s3\_force\_destroy](#input\_truefoundry\_s3\_force\_destroy) | Force destroy for mlfoundry s3 bucket | `bool` | `false` | no |
| <a name="input_truefoundry_s3_ignore_public_acls"></a> [truefoundry\_s3\_ignore\_public\_acls](#input\_truefoundry\_s3\_ignore\_public\_acls) | Ignore public ACLs for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_s3_override_name"></a> [truefoundry\_s3\_override\_name](#input\_truefoundry\_s3\_override\_name) | Override name for s3 bucket. truefoundry\_s3\_enable\_override must be set true | `string` | `""` | no |
| <a name="input_truefoundry_s3_restrict_public_buckets"></a> [truefoundry\_s3\_restrict\_public\_buckets](#input\_truefoundry\_s3\_restrict\_public\_buckets) | Restrict public buckets for mlfoundry s3 bucket | `bool` | `true` | no |
| <a name="input_truefoundry_service_account"></a> [truefoundry\_service\_account](#input\_truefoundry\_service\_account) | Truefoundry k8s service account name | `string` | `"truefoundry"` | no |
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
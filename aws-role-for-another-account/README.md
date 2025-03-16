# role-for-another-account

create role to trust another account (so that account can assume role)

```tf
module "role-for-acc_manager" {
  source = "github.com/linolabx/tfmodules?ref=aws-role-for-another-account@v0.0.1"

  providers = { aws = aws.secret }

  name_prefix     = "Administrator"
  trusted_account = aws_organizations_account.manager.id
  policies        = ["AdministratorAccess"]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.29.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.29.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_role_policy_attachment) | resource |
| [random_pet.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_mfa"></a> [mfa](#input\_mfa) | force session to use MFA to assume role | `bool` | `false` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | prefix for role name | `string` | `"TerraformManagedRole"` | no |
| <a name="input_policies"></a> [policies](#input\_policies) | policies to attach to role | `set(string)` | n/a | yes |
| <a name="input_trusted_account"></a> [trusted\_account](#input\_trusted\_account) | allow this account to assume specified role | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | n/a |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | n/a |

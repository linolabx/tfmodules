# org-account-manager

create an "entry" account in AWS Organizations

you can create users in this account and let them assume role in other accounts

```terraform
module "acc_manager" {
  source = "github.com/linolabx/tfmodules?ref=aws-org-account@v0.0.1-manager"

  providers = { aws = aws.root }

  credential = local.aws_cred

  name  = "manager"
  email = "manager@example.com"
}

provider "aws" {
  alias = "manager"

  region     = ....region
  access_key = ....access_key
  secret_key = ....secret_key
  assume_role { role_arn = module.acc_manager.role_arn }
}

# module.acc_manager.account_id
# module.acc_manager.group.self_managing
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.29.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.29.0 |
| <a name="provider_aws.this"></a> [aws.this](#provider\_aws.this) | 5.29.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_normalized"></a> [normalized](#module\_normalized) | github.com/linolabx/tfmodules?ref=aws-normalized@v0.0.1 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_group.self_managing](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_group) | resource |
| [aws_iam_group_policy_attachment.iam_read_only_access](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_group_policy_attachment.iam_self_manage_service_specific_credentials](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_group_policy_attachment.iam_user_change_password](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_group_policy_attachment.self_manage_vmfa](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_group_policy_attachment) | resource |
| [aws_iam_policy.self_manage_vmfa](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/iam_policy) | resource |
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/organizations_account) | resource |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_credential"></a> [credential](#input\_credential) | credential of parent account | <pre>object({<br>    region     = string<br>    access_key = string<br>    secret_key = string<br>  })</pre> | n/a | yes |
| <a name="input_email"></a> [email](#input\_email) | email of the account | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | name of the account | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | role that created for parent account to assume | `string` | `"OrganizationAccountAccessRole"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_group"></a> [group](#output\_group) | n/a |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | root role for parent account to assume |

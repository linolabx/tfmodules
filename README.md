# org-account

create an account in AWS Organizations, make it trusted specified account, and create admin role for human and service users.

```terraform
module "acc_linolab" {
  source = "github.com/linolabx/tfmodules?ref=aws-org-account@v0.0.1"

  providers = { aws = aws.root }

  credential = local.aws_cred

  name  = "linolab"
  email = "linolab@example.com"

  trusted_account_id = aws_organizations_account.manager.id
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

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_role_admin"></a> [role\_admin](#module\_role\_admin) | github.com/linolabx/tfmodules?ref=aws-role-for-another-account@v0.0.1 | n/a |
| <a name="module_role_admin_required_mfa"></a> [role\_admin\_required\_mfa](#module\_role\_admin\_required\_mfa) | github.com/linolabx/tfmodules?ref=aws-role-for-another-account@v0.0.1 | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_organizations_account.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/resources/organizations_account) | resource |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/5.29.0/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_credential"></a> [credential](#input\_credential) | credential of parent account | <pre>object({<br>    region     = string<br>    access_key = string<br>    secret_key = string<br>  })</pre> | n/a | yes |
| <a name="input_email"></a> [email](#input\_email) | email of the account | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | name of the account | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | role that created for parent account to assume | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_trusted_account_id"></a> [trusted\_account\_id](#input\_trusted\_account\_id) | allow this account to assume specified roles | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | n/a |
| <a name="output_role"></a> [role](#output\_role) | roles that created for other accounts to assume |
| <a name="output_root_role_arn"></a> [root\_role\_arn](#output\_root\_role\_arn) | role that created for parent account to assume |

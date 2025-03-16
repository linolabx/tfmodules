terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "name" {
  type        = string
  description = "name of the account"
}

variable "email" {
  type        = string
  description = "email of the account"
}

variable "role_name" {
  type        = string
  default     = "OrganizationAccountAccessRole"
  description = "role that created for parent account to assume"
}

variable "trusted_account_id" {
  type        = string
  description = "allow this account to assume specified roles"
}

variable "credential" {
  type = object({
    region     = string
    access_key = string
    secret_key = string
  })
  description = "credential of parent account"
}

resource "aws_organizations_account" "this" {
  name      = var.name
  email     = var.email
  role_name = "OrganizationAccountAccessRole"

  lifecycle {
    ignore_changes = [role_name]
  }
}

data "aws_partition" "this" {}

locals { account_role_arn = "arn:${data.aws_partition.this.partition}:iam::${aws_organizations_account.this.id}:role/OrganizationAccountAccessRole" }

provider "aws" {
  alias = "this"

  region     = var.credential.region
  access_key = var.credential.access_key
  secret_key = var.credential.secret_key
  assume_role { role_arn = local.account_role_arn }
}

module "role_admin" {
  source = "github.com/linolabx/tfmodules?ref=aws-role-for-another-account@v0.0.1"

  providers = { aws = aws.this }

  name_prefix     = "Administrator"
  trusted_account = var.trusted_account_id
  policies        = ["AdministratorAccess"]
}

module "role_admin_required_mfa" {
  source = "github.com/linolabx/tfmodules?ref=aws-role-for-another-account@v0.0.1"

  providers = { aws = aws.this }

  name_prefix     = "Administrator"
  trusted_account = var.trusted_account_id
  policies        = ["AdministratorAccess"]
  mfa             = true
}

output "account_id" { value = aws_organizations_account.this.id }
output "root_role_arn" {
  description = "role that created for parent account to assume"
  value       = local.account_role_arn
}

output "role" {
  description = "roles that created for other accounts to assume"
  value = {
    admin = {
      account_id = aws_organizations_account.this.id
      role_name  = module.role_admin.role_name
      role_arn   = module.role_admin.role_arn
    }
    admin_required_mfa = {
      account_id = aws_organizations_account.this.id
      role_name  = module.role_admin_required_mfa.role_name
      role_arn   = module.role_admin_required_mfa.role_arn
    }
  }
}

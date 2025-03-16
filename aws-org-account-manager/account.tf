
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

locals { root_role = "arn:${data.aws_partition.this.partition}:iam::${aws_organizations_account.this.id}:role/OrganizationAccountAccessRole" }

provider "aws" {
  alias = "this"

  region     = var.credential.region
  access_key = var.credential.access_key
  secret_key = var.credential.secret_key
  assume_role { role_arn = local.root_role }
}

output "account_id" { value = aws_organizations_account.this.id }
output "role_arn" {
  description = "root role for parent account to assume"
  value       = local.root_role
}

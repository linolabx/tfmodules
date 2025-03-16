terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }
  }
}

variable "name" {
  type        = string
  description = "username"
}

variable "groups" {
  type        = list(string)
  default     = []
  description = "groups to attach to user"
}

variable "create_access_key" {
  type        = bool
  description = "create access key for user"
  default     = false
}

variable "create_login_profile" {
  type        = bool
  description = "create login profile for user"
  default     = false
}

variable "roles" {
  type        = list(string)
  default     = []
  description = "roles that user can assume"
}

variable "external_roles" {
  type = list(object({
    account_id = string
    role_name  = string
  }))
  default     = []
  description = "external roles that user can assume, used for assume role from another account"
}

data "aws_partition" "this" {}
data "aws_caller_identity" "this" {}

locals { role_arns = concat(
  [for role in var.roles : "arn:${data.aws_partition.this.partition}:iam::${data.aws_caller_identity.this.account_id}:role/${role}"],
  [for ext in var.external_roles : "arn:${data.aws_partition.this.partition}:iam::${ext.account_id}:role/${ext.role_name}"]
) }

resource "aws_iam_user" "this" { name = var.name }

resource "aws_iam_user_group_membership" "this" {
  user   = aws_iam_user.this.name
  groups = var.groups
}

resource "aws_iam_user_login_profile" "this" {
  count                   = var.create_login_profile ? 1 : 0
  user                    = aws_iam_user.this.name
  password_reset_required = false
}

resource "aws_iam_access_key" "this" {
  count = var.create_access_key ? 1 : 0
  user  = aws_iam_user.this.name
}

resource "aws_iam_user_policy" "this" {
  count = length(local.role_arns) > 0 ? 1 : 0

  user = aws_iam_user.this.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = "sts:AssumeRole",
      Effect   = "Allow",
      Resource = local.role_arns
    }]
  })
}

output "name" { value = aws_iam_user.this.name }
output "arn" { value = aws_iam_user.this.arn }
output "access_key" { value = var.create_access_key ? aws_iam_access_key.this[0].id : null }
output "secret_key" {
  value     = var.create_access_key ? aws_iam_access_key.this[0].secret : null
  sensitive = true
}
output "password" {
  value     = var.create_login_profile ? aws_iam_user_login_profile.this[0].password : null
  sensitive = true
}

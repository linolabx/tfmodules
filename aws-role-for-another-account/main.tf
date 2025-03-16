terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }
  }
}

variable "name_prefix" {
  type        = string
  default     = "TerraformManagedRole"
  description = "prefix for role name"
}

variable "trusted_account" {
  type        = string
  description = "allow this account to assume specified role"
}

variable "policies" {
  type        = set(string)
  description = "policies to attach to role"
}

variable "mfa" {
  type        = bool
  description = "force session to use MFA to assume role"
  default     = false
}

data "aws_partition" "this" {}

resource "random_pet" "this" {}
resource "aws_iam_role" "this" {
  name = "${var.name_prefix}${var.mfa ? "-MFA" : ""}-${random_pet.this.id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:${data.aws_partition.this.partition}:iam::${var.trusted_account}:root" }
      Action    = "sts:AssumeRole"
      Condition = var.mfa ? { Bool = { "aws:MultiFactorAuthPresent" = "true" } } : {}
    }]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.policies

  policy_arn = "arn:${data.aws_partition.this.partition}:iam::aws:policy/${each.key}"
  role       = aws_iam_role.this.name
}

output "role_name" { value = aws_iam_role.this.name }
output "role_arn" { value = aws_iam_role.this.arn }

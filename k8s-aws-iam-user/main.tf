terraform {
  backend "local" { path = "../../.secret/tfstates/net.sxxfuture.infra/secret/terraform.tfstate" }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

variable "cluster_name" { type = string }
variable "namespace" { type = string }
variable "service_name" { type = string }
variable "policy" { type = any }

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

locals { name = "${var.cluster_name}.${var.namespace}.${var.service_name}.${random_string.suffix.result}" }

resource "aws_iam_user" "this" { name = local.name }
resource "aws_iam_user_policy" "this" {
  name   = local.name
  user   = aws_iam_user.this.name
  policy = jsonencode(var.policy)
}
resource "aws_iam_access_key" "this" { user = aws_iam_user.this.name }

output "access_key" { value = aws_iam_access_key.this }

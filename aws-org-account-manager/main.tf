terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "normalized" {
  providers = { aws = aws.this }
  source    = "github.com/linolabx/tfmodules?ref=aws-normalized@v0.0.1"
}

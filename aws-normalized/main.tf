terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.29.0"
    }
  }
}

data "aws_partition" "this" {}

resource "aws_iam_policy" "iam_self_manage_service_specific_credentials" {
  count = data.aws_partition.this.partition == "aws-cn" ? 1 : 0

  name   = "IAMSelfManageServiceSpecificCredentials"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateServiceSpecificCredential",
        "iam:ListServiceSpecificCredentials",
        "iam:UpdateServiceSpecificCredential",
        "iam:DeleteServiceSpecificCredential",
        "iam:ResetServiceSpecificCredential"
      ],
      "Resource": "arn:aws-cn:iam::*:user/$${aws:username}"
    }
  ]
}
EOF
}

output "iam_policy" {
  value = {
    iam_self_manage_service_specific_credentials = data.aws_partition.this.partition == "aws-cn" ? aws_iam_policy.iam_self_manage_service_specific_credentials.0.arn : "arn:${data.aws_partition.this.partition}:iam::aws:policy/IAMSelfManageServiceSpecificCredentials"
  }
}

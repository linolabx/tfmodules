resource "aws_iam_group" "self_managing" {
  provider = aws.this

  name = "SelfManaging"
}

resource "aws_iam_group_policy_attachment" "iam_read_only_access" {
  provider = aws.this

  group      = aws_iam_group.self_managing.name
  policy_arn = "arn:${data.aws_partition.this.partition}:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "iam_self_manage_service_specific_credentials" {
  provider = aws.this

  depends_on = [module.normalized]

  group      = aws_iam_group.self_managing.name
  policy_arn = module.normalized.iam_policy.iam_self_manage_service_specific_credentials
}

resource "aws_iam_group_policy_attachment" "iam_user_change_password" {
  provider = aws.this

  group      = aws_iam_group.self_managing.name
  policy_arn = "arn:${data.aws_partition.this.partition}:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_policy" "self_manage_vmfa" {
  provider = aws.this

  name = "SelfManageVMFA"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Allow users to manage their own MFA devices
      {
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "iam:DeleteVirtualMFADevice"
        ]
        Resource = [
          "arn:${data.aws_partition.this.partition}:iam::*:user/$${aws:username}",
          # aws cn allows only one MFA device per user
          data.aws_partition.this.partition == "aws-cn"
          ? "arn:aws-cn:iam::*:mfa/$${aws:username}"
          : "arn:aws:iam::*:mfa/$${aws:username}-*",
        ]
      },
      # Allow users to deactivate their own MFA devices if they signin with MFA
      {
        Sid    = "AllowUsersToDeactivateTheirOwnVirtualMFADevice",
        Effect = "Allow",
        Action = [
          "iam:DeactivateMFADevice"
        ],
        Resource = [
          "arn:${data.aws_partition.this.partition}:iam::*:user/$${aws:username}",
          # aws cn allows only one MFA device per user
          data.aws_partition.this.partition == "aws-cn"
          ? "arn:aws-cn:iam::*:mfa/$${aws:username}"
          : "arn:aws:iam::*:mfa/$${aws:username}-*",
        ],
        Condition = { Bool = { "aws:MultiFactorAuthPresent" = "true" } }
      },
      # General IAM permissions
      {
        Effect = "Allow"
        Action = [
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ListUsers"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "self_manage_vmfa" {
  provider = aws.this

  group      = aws_iam_group.self_managing.name
  policy_arn = aws_iam_policy.self_manage_vmfa.arn
}

output "group" {
  value = { self_managing = aws_iam_group.self_managing.name }
}

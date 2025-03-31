data "aws_region" "this" {}

locals { envs = {
  AWS_REGION            = data.aws_region.this.name
  AWS_ACCESS_KEY_ID     = aws_iam_access_key.this.id
  AWS_SECRET_ACCESS_KEY = aws_iam_access_key.this.secret
} }

output "envs" { value = local.envs }

variable "use_secret" {
  type    = bool
  default = false
}
resource "kubernetes_secret" "this" {
  count = var.use_secret ? 1 : 0
  metadata {
    name      = "${var.service_name}-${random_string.suffix.result}"
    namespace = var.namespace
  }
  data = local.envs
}
output "secret" { value = var.use_secret ? kubernetes_secret.this[0].metadata[0].name : null }

variable "module_rel" {
  type        = string
  description = "The relative path to the module"
  default     = null
}

data "external" "project" {
  program = ["python3", "${path.module}/proj.py"]
  query   = { current_module = abspath(path.root) }
}

locals {
  info = data.external.project.result
}

locals {
  project_base_dir    = local.info.project_base_dir
  project_secrets_dir = "${local.project_base_dir}/.secret"

  module_rel   = var.module_rel != null ? var.module_rel : local.info.module_rel
  secrets_dir  = "${local.project_secrets_dir}/secrets/${local.module_rel}"
  tfstate_dir  = "${local.project_secrets_dir}/tfstates/${local.module_rel}"
  tfstate_file = "${local.tfstate_dir}/terraform.tfstate"

  cred_file    = "${local.secrets_dir}/cred.yaml"
  outputs_file = "${local.secrets_dir}/outputs.yaml"
}

output "project" {
  value = {
    base_dir    = local.project_base_dir,
    secrets_dir = local.project_secrets_dir,
  }
}

output "module_rel" { value = local.module_rel }
output "secrets_dir" { value = local.secrets_dir }
output "tfstate_dir" { value = local.tfstate_dir }
output "tfstate_file" { value = local.tfstate_file }

output "outputs_file" { value = local.outputs_file }

output "cred" { value = try(sensitive(yamldecode(file(local.cred_file))), null) }
output "outputs" { value = try(sensitive(yamldecode(file(local.outputs_file))), null) }

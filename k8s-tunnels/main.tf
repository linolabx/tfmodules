terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

variable "cluster_url" { type = string }
variable "namespace" { type = string }

variable "forwards" {
  type = map(object({
    # pod, service, deployment
    type = string
    # resource name
    name = string
    # port: port number or name
    port = string
  }))
}

locals {
  base_dir = abspath("${path.root}/.terraform/tmp/port-forward-${random_string.suffix.result}")
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

data "external" "port_forward" {
  program = ["python3", "${path.module}/port-forward.py"]
  query = {
    instance_id = random_string.suffix.result
    module_dir  = path.module
    tmp_dir     = local.base_dir
    forwards    = jsonencode(var.forwards)
    kubeconfig = yamlencode({
      apiVersion = "v1"
      kind       = "Config"
      clusters = [{
        name = "default"
        cluster = {
          server                     = var.cluster_url
          certificate-authority-data = base64encode(kubernetes_secret.this.data["ca.crt"])
        }
      }]
      users = [{
        name = "default"
        user = { token = kubernetes_secret.this.data["token"] }
      }]
      contexts = [{
        name = "default"
        context = {
          cluster   = "default"
          namespace = var.namespace
          user      = "default"
        }
      }]
      current-context = "default"
      preferences     = {}
    })
  }
}

output "tunnels" {
  value = jsondecode(data.external.port_forward.result["forwards"])
}

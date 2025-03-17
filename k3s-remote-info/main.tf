variable "user" { type = string }
variable "host" { type = string }
variable "port" {
  type    = number
  default = 22
}
variable "private_key" {
  type    = string
  default = null
}

data "external" "k3s" {
  program = ["python3", "${path.module}/waitk3s.py"]

  query = {
    connection = jsonencode({
      user        = var.user
      host        = var.host
      port        = var.port
      private_key = var.private_key
    })
  }
}

locals {
  kc_text = data.external.k3s.result["kubeconfig"]
  kc      = yamldecode(local.kc_text)

  k3sc_text = data.external.k3s.result["k3sconfig"]
  k3sc      = yamldecode(local.k3sc_text)
}

output "kubeconfig" {
  value = sensitive(local.kc_text)
}

output "cred" {
  value = {
    host                   = local.kc.clusters[0].cluster.server
    cluster_ca_certificate = sensitive(base64decode(local.kc.clusters[0].cluster.certificate-authority-data))
    client_certificate     = sensitive(base64decode(local.kc.users[0].user.client-certificate-data))
    client_key             = sensitive(base64decode(local.kc.users[0].user.client-key-data))
  }
}

output "k3sconfig" { value = sensitive(local.k3sc_text) }

output "agent_token" { value = sensitive(lookup(local.k3sc, "agent-token", null)) }

output "node" {
  value = {
    role        = lookup(local.k3sc, "agent-token", null) == null ? "server" : "agent"
    external_ip = local.k3sc["node-external-ip"]
    labels      = local.k3sc["node-label"]
    name        = local.k3sc["node-name"]
  }
}

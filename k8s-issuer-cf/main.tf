terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

variable "cluster_name" {
  type        = string
  description = "name of the k8s cluster"
}

variable "namespace" {
  type        = string
  description = "namespace for this issuer"
}

variable "identifier" {
  type        = string
  default     = null
  description = "issuer identifier, if not provided, will use namespace as default"
}

locals { identifier = var.identifier != null ? var.identifier : var.namespace }

variable "acme" {
  type = object({
    email  = optional(string, "acme@linolab.cn")
    server = optional(string, "https://acme-v02.api.letsencrypt.org/directory")
  })
  default     = {}
  description = "acme configuration"
}

variable "cloudflare" {
  type = object({
    email      = string
    account_id = string
  })
  description = "cloudflare account information"
}

variable "zones" {
  type = list(object({
    id = string
  }))
  description = "cloudflare zones"
}

data "cloudflare_api_token_permission_groups" "all" {}

resource "cloudflare_api_token" "this" {
  name = "k8s.${var.cluster_name}.${local.identifier}.acme"

  policy {
    permission_groups = [data.cloudflare_api_token_permission_groups.all.zone["Zone Read"]]
    resources         = { "com.cloudflare.api.account.${var.cloudflare.account_id}" = "*" }
  }
  policy {
    permission_groups = [data.cloudflare_api_token_permission_groups.all.zone["DNS Write"]]
    resources         = { for z in var.zones : "com.cloudflare.api.account.zone.${z.id}" => "*" }
  }
}

resource "kubernetes_secret" "cf_token" {
  metadata {
    name      = "${local.identifier}.cloudflare-token"
    namespace = var.namespace
  }

  data = { token = cloudflare_api_token.this.value }
}

resource "kubernetes_manifest" "issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata   = { name = "${local.identifier}.issuer", namespace = var.namespace }
    spec = {
      acme = {
        email               = var.acme.email
        privateKeySecretRef = { name = "${local.identifier}.account-key" }
        server              = var.acme.server
        solvers = [{ dns01 = { cloudflare = {
          email             = var.cloudflare.email
          apiTokenSecretRef = { name = kubernetes_secret.cf_token.metadata[0].name, key = "token" }
        } } }]
      }
    }
  }
}

output "cloudflare_creds" {
  value = {
    email      = nonsensitive(var.cloudflare.email)
    account_id = nonsensitive(var.cloudflare.account_id)
    api_token  = sensitive(cloudflare_api_token.this.value)
  }
}

output "issuer" {
  value = {
    name = nonsensitive(kubernetes_manifest.issuer.manifest.metadata.name)
    kind = nonsensitive(kubernetes_manifest.issuer.manifest.kind)
  }
}

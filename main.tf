terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

variable "k8s_name" {
  type        = string
  description = "k8s cluster name, used for auto generate resource names"
}

variable "k8s_namespace" {
  type        = string
  default     = "cert-manager"
  description = "namespace for this issue, if not provided, will create an cluster-issuer"
}

variable "name" {
  type        = string
  description = "name for this issue"
}

variable "acme_email" {
  type        = string
  description = "email for acme"
}

variable "acme_server" {
  type        = string
  description = "acme server"
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "cf_email" {
  type        = string
  description = "cloudflare email"
}

variable "cf_account_id" {
  type        = string
  description = "cloudflare account id"
}

variable "cf_zone_ids" {
  type        = list(string)
  description = "cloudflare zones"
}

locals {
  is_cluster = var.k8s_namespace == "cert-manager"
}

module "permission_group" {
  source     = "github.com/linolabx/tfmodule-cloudflare?ref=permission-group@v0.0.2"
  account_id = var.cf_account_id
}

resource "cloudflare_account_token" "this" {
  account_id = var.cf_account_id
  name       = "k8s.${var.k8s_name}.${var.name}.acme"
  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = module.permission_group.zone["Zone Read"] },
      ],
      resources = {
        "com.cloudflare.api.account.${var.cf_account_id}" = "*"
      }
    },
    {
      effect = "allow"
      permission_groups = [
        { id = module.permission_group.zone["DNS Write"] }
      ]
      resources = {
        for id in var.cf_zone_ids : "com.cloudflare.api.account.zone.${id}" => "*"
      }
    }
  ]
}

resource "kubernetes_secret" "cf_token" {
  metadata {
    name      = "${var.name}.cloudflare-token"
    namespace = var.k8s_namespace
  }

  # TOOD: remove this after next release
  # https://github.com/cloudflare/terraform-provider-cloudflare/issues/5232
  lifecycle { ignore_changes = [data] }

  data = { token = cloudflare_account_token.this.value }
}

resource "kubernetes_manifest" "clusterissuer" {
  count = local.is_cluster ? 1 : 0

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = { name = "${var.name}.cluster-issuer" }

    spec = {
      acme = {
        email               = var.acme_email
        privateKeySecretRef = { name = "${var.name}.account-key" }
        server              = var.acme_server
        solvers = [{
          dns01 = {
            cloudflare = {
              email = var.cf_email
              apiTokenSecretRef = {
                name = kubernetes_secret.cf_token.metadata[0].name
                key  = "token"
            } }
          }
        }]
      }
    }
  }
}


resource "kubernetes_manifest" "issuer" {
  count = local.is_cluster ? 0 : 1

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"

    metadata = { name = "${var.name}.issuer", namespace = var.k8s_namespace }

    spec = {
      acme = {
        email               = var.acme_email
        privateKeySecretRef = { name = "${var.name}.account-key" }
        server              = var.acme_server
        solvers = [{
          dns01 = {
            cloudflare = {
              email = var.cf_email
              apiTokenSecretRef = {
                name = kubernetes_secret.cf_token.metadata[0].name
                key  = "token"
              }
            }
          }
        }]
      }
    }
  }
}


locals {
  issuer = local.is_cluster ? kubernetes_manifest.clusterissuer[0] : kubernetes_manifest.issuer[0]
}

output "name" {
  value = nonsensitive(local.issuer.manifest.metadata.name)
}

output "kind" {
  value = nonsensitive(local.issuer.manifest.kind)
}

output "namespace" {
  value = nonsensitive(var.k8s_namespace)
}

output "private_key" {
  value = nonsensitive("${var.name}.account-key")
}

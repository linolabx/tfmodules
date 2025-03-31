terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "~> 1.0"
    }
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

variable "namespace" {
  type        = string
  description = "namespace to deploy to"
}

variable "hostmap" {
  type = list(object({
    domain  = string
    app     = optional(string, null)
    service = optional(string, null)
    port    = number
  }))
  description = "map of domains to apps or services"
}

check "hostmap_conflict" {
  assert {
    condition     = alltrue([for h in var.hostmap : (h.app != null ? 1 : 0) + (h.service != null ? 1 : 0) == 1])
    error_message = "for each hostmap entry, either app or service must be provided, but not both"
  }
}

locals {
  readable_identifier = substr(join("-", sort(distinct([
    for hm in var.hostmap : hm.app == null ? hm.service : hm.app
  ]))), 0, 64)
}

variable "issuer" { type = object({
  name = string
  kind = optional(string, "cluster-issuer")
}) }

variable "ingress_tls" {
  type = list(object({
    hosts       = list(string)
    secret_name = string
  }))
  default = []
}

variable "cert_domains" {
  type    = list(string)
  default = []
}

variable "redirect_https" {
  type    = bool
  default = true
}

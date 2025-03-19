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

variable "namespace" {
  type        = string
  description = "namespace to deploy to"
}

variable "app" {
  type = object({
    name = string
    port = number
  })
  default     = null
  description = "this module will create a service for the app, ignored if `service` variable is provided"
}

variable "service" {
  type = object({
    name = string
    port = map(any)
  })
  description = "service to use for ingress, if provided, `app` variable is ignored"
  default     = null
}
locals {
  service = var.service == null ? {
    name = "${var.app.name}-svc"
    port = { name = "http" }
  } : var.service

  service_port_name   = lookup(local.service.port, "name", null)
  service_port_number = lookup(local.service.port, "number", null)
}
check "port_conflict" {
  assert {
    condition     = (local.service_port_name == null) != (local.service_port_number == null)
    error_message = "service port name and number cant be set at the same time"
  }
}

variable "domain" {
  type    = string
  default = null
}
variable "domains" {
  type    = list(string)
  default = []
}
check "domain_exists" {
  assert {
    condition     = length(local.domains) > 0
    error_message = "domains must be provided"
  }
}
check "domain_dupset" {
  assert {
    condition     = (var.domain == null) != (length(var.domains) == 0)
    error_message = "domain and domains cant be set at the same time"
  }
}
locals {
  domains = var.domain == null ? var.domains : [var.domain]
}

variable "issuer" { type = string }

variable "issuer_kind" {
  type    = string
  default = "cluster-issuer"
}

variable "tls" { type = list(object({
  hosts       = list(string)
  secret_name = string
})) }

variable "cors" {
  type = object({
    origins = list(string)
    methods = list(string)
  })
  default = null
}

variable "redirect_https" {
  type    = bool
  default = false
}

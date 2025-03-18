terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.0"
    }
  }
}

variable "name" {
  type        = string
  description = "The name of the database and superuser to the database"
}

variable "add_suffix" {
  type        = bool
  description = "If true, will add a random suffix to name"
  default     = false
}

resource "random_pet" "name" {
  count   = var.name == null ? 1 : 0
  keepers = { name = var.name }
}

resource "random_string" "suffix" {
  count   = var.add_suffix ? 1 : 0
  keepers = { name = var.name }
  length  = 8
  special = false
  upper   = false
}

locals {
  raw_name = var.name == null ? random_pet.name[0].id : var.name
  name     = var.add_suffix ? "${local.raw_name}-${random_string.suffix[0].result}" : local.raw_name
}

resource "random_password" "this" {
  length  = 24
  special = false
}

resource "postgresql_role" "this" {
  name     = local.name
  login    = true
  password = random_password.this.result
}

resource "postgresql_database" "this" {
  name       = local.name
  owner      = local.name
  lc_collate = "en_US.utf8"
}

output "database" {
  value = postgresql_database.this.name
}

output "username" {
  value = postgresql_role.this.name
}

output "password" {
  value     = postgresql_role.this.password
  sensitive = true
}

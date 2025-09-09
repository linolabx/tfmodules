terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

variable "namespace" { type = string }
variable "name" { type = string }
variable "capacity" { type = string }
variable "storage_host" { type = string }
variable "storage_endpoint" { type = string }

variable "pv_reclaim_policy" {
  type    = string
  default = "Retain"
}
variable "access_modes" {
  type    = list(string)
  default = ["ReadWriteOnce"]
}
variable "host_path_type" {
  type    = string
  default = "DirectoryOrCreate"
}

locals {
  volume_name = "${var.namespace}.${var.name}"
  volume_path = "/mnt/${var.storage_endpoint}/volumes/${local.volume_name}"
}

resource "terraform_data" "storage_host" { input = var.storage_host }

resource "kubernetes_persistent_volume" "this" {
  lifecycle {
    replace_triggered_by = [terraform_data.storage_host]
  }

  metadata {
    name = local.volume_name
  }

  spec {
    persistent_volume_source {
      host_path {
        path = local.volume_path
        type = var.host_path_type
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = [var.storage_host]
          }
        }
      }
    }

    capacity                         = { storage = var.capacity }
    volume_mode                      = "Filesystem"
    persistent_volume_reclaim_policy = var.pv_reclaim_policy
    storage_class_name               = "local-storage"
    access_modes                     = var.access_modes
  }
}

resource "kubernetes_persistent_volume_claim" "this" {
  lifecycle {
    replace_triggered_by = [terraform_data.storage_host]
  }

  depends_on = [kubernetes_persistent_volume.this]

  metadata {
    namespace = var.namespace
    name      = var.name
  }
  wait_until_bound = false
  spec {
    resources { requests = { storage = var.capacity } }
    access_modes       = var.access_modes
    storage_class_name = "local-storage"
    volume_name        = local.volume_name
  }
}

output "pvc_name" { value = kubernetes_persistent_volume_claim.this.metadata.0.name }
output "volume_path" { value = local.volume_path }
output "volume_name" { value = local.volume_name }

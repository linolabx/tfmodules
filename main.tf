terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.2"
    }
  }
}

variable "account_id" {
  type    = string
  default = ""
}

data "cloudflare_accounts" "all" {
  count     = var.account_id != "" ? 0 : 1
  max_items = 2
}

locals {
  account_id = var.account_id != "" ? var.account_id : length(data.cloudflare_accounts.all[0].result) == 1 ? data.cloudflare_accounts.all[0].result[0].id : ""
}

check "account_id" {
  assert {
    condition     = local.account_id != ""
    error_message = "account_id is required or there must be only one account"
  }
}

data "cloudflare_account_api_token_permission_groups_list" "all" { account_id = local.account_id }

output "zone" {
  value = { for r in data.cloudflare_account_api_token_permission_groups_list.all.result : r.name => r.id if contains(r.scopes, "com.cloudflare.api.account.zone") }
}

output "account" {
  value = { for r in data.cloudflare_account_api_token_permission_groups_list.all.result : r.name => r.id if contains(r.scopes, "com.cloudflare.api.account") }
}

output "bucket" {
  value = { for r in data.cloudflare_account_api_token_permission_groups_list.all.result : r.name => r.id if contains(r.scopes, "com.cloudflare.edge.r2.bucket") }
}

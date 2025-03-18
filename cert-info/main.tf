variable "certificate" {
  type        = string
  description = "the certificate to get info about"
  default     = null
}

data "external" "project" {
  program = ["python3", "${path.module}/cert-info.py"]
  query   = { certificate = var.certificate }
}

output "x509" { value = data.external.project.result.x509 }
output "raw" { value = data.external.project.result.base64 }

output "fingerprint" {
  value = {
    sha1 = {
      base64    = data.external.project.result.fingerprint_sha1_base64
      hex       = data.external.project.result.fingerprint_sha1_hex
      formatted = data.external.project.result.fingerprint_sha1_formatted
    },
    sha256 = {
      base64    = data.external.project.result.fingerprint_sha256_base64
      hex       = data.external.project.result.fingerprint_sha256_hex
      formatted = data.external.project.result.fingerprint_sha256_formatted
    },
  }
}

output "formatted_fingerprint" {
  value = data.external.project.result.fingerprint_sha1_formatted
}

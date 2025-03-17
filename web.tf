resource "kubernetes_service" "this" {
  count = var.service == null ? 1 : 0
  metadata {
    namespace = var.namespace
    name      = local.service.name
  }

  spec {
    port {
      name = local.service_port_name
      port = var.app.port
    }

    selector = { app = var.app.name }
  }
}

resource "kubernetes_manifest" "cors" {
  count = var.cors == null ? 0 : 1
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      namespace = var.namespace
      name      = "${local.service.name}-cors"
    }
    spec = {
      headers = {
        accessControlAllowMethods    = var.cors.methods
        accessControlAllowHeaders    = ["*"]
        accessControlAllowOriginList = var.cors.origins
        accessControlMaxAge          = 100
        addVaryHeader                = true
      }
    }
  }
}

resource "kubernetes_manifest" "redirect_https" {
  count = var.redirect_https ? 1 : 0
  manifest = {
    apiVersion = "traefik.containo.us/v1alpha1"
    kind       = "Middleware"
    metadata = {
      namespace = var.namespace
      name      = "${local.service.name}-redirect-https"
    }
    spec = {
      redirectScheme = {
        scheme    = "https"
        permanent = true
      }
    }
  }
}

locals {
  middlewares = compact([
    var.cors == null ? "" : "${var.namespace}-${kubernetes_manifest.cors[0].manifest.metadata.name}@kubernetescrd",
    !var.redirect_https ? "" : "${var.namespace}-${kubernetes_manifest.redirect_https[0].manifest.metadata.name}@kubernetescrd",
  ])

  middleware_annotations = merge(
    length(local.middlewares) == 0 ? {} : {
      "traefik.ingress.kubernetes.io/router.middlewares" = join(",", local.middlewares)
    }
  )
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    namespace = var.namespace
    name      = "${local.service.name}-${local.service_port_name == null ? local.service_port_number : local.service_port_name}-ingress"
    annotations = merge({
      "cert-manager.io/${provider::corefunc::str_kebab(var.issuer_kind)}" = var.issuer

      "kubernetes.io/ingress.class" = "traefik"
    }, local.middleware_annotations)
  }

  spec {
    dynamic "tls" {
      for_each = var.tls
      content {
        hosts       = tls.value.hosts
        secret_name = tls.value.secret_name
      }
    }

    dynamic "rule" {
      for_each = local.domains
      content {
        host = rule.value
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = local.service.name
                dynamic "port" {
                  for_each = local.service_port_number == null ? [] : [1]
                  content {
                    number = local.service_port_number
                  }
                }
                dynamic "port" {
                  for_each = local.service_port_name == null ? [] : [1]
                  content {
                    name = local.service_port_name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

output "service_hostname" {
  value       = "${local.service.name}.${var.namespace}.svc.cluster.local"
  description = "service hostname used in kubernetes, e.g. srv-name.namespace.svc.cluster.local"
}

output "service_port" {
  value       = var.app == null ? null : var.app.port
  description = "service port used in kubernetes, e.g. 8080"
}

output "service_hostport" {
  value       = var.app == null ? null : "${local.service.name}.${var.namespace}.svc.cluster.local:${var.app.port}"
  description = "service host and port used in kubernetes, e.g. srv-name.namespace.svc.cluster.local:8080"
}

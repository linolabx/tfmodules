locals {
  _app_service = { for hm in var.hostmap : hm.app => hm... if hm.app != null }

  services = { for app, srvs in local._app_service : app => {
    app   = app
    srv   = "${app}-${random_string.suffix.result}"
    ports = distinct([for srv in srvs : srv.port])
  } }
}

resource "kubernetes_service" "this" {
  for_each = local.services

  metadata {
    namespace = var.namespace
    name      = each.value.srv
  }

  spec {
    selector = { app = each.value.app }
    dynamic "port" {
      for_each = each.value.ports
      content {
        name = "http-${port.value}"
        port = port.value
      }
    }
  }
}

resource "kubernetes_manifest" "redirect_https" {
  count = var.redirect_https ? 1 : 0
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      namespace = var.namespace
      name      = "redirect-https-${random_string.suffix.result}"
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
    !var.redirect_https ? "" : "${var.namespace}-${kubernetes_manifest.redirect_https[0].manifest.metadata.name}@kubernetescrd",
  ])

  middleware_annotations = length(local.middlewares) == 0 ? {} : {
    "traefik.ingress.kubernetes.io/router.middlewares" = join(",", local.middlewares)
  }

  issuer_annotations = var.issuer != null ? {
    "cert-manager.io/${provider::corefunc::str_kebab(var.issuer.kind)}" = var.issuer.name
  } : {}
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    namespace   = var.namespace
    name        = "${local.readable_identifier}-${random_string.suffix.result}"
    annotations = merge({ "kubernetes.io/ingress.class" = "traefik" }, local.issuer_annotations, local.middleware_annotations)
  }

  spec {
    dynamic "tls" {
      for_each = var.ingress_tls
      content {
        hosts       = tls.value.hosts
        secret_name = tls.value.secret_name
      }
    }

    dynamic "tls" {
      for_each = var.cert_domains
      content {
        hosts       = ["*.${tls.value}", tls.value]
        secret_name = "tls-${tls.value}"
      }
    }

    dynamic "rule" {
      for_each = var.hostmap
      content {
        host = rule.value.domain
        http {
          path {
            path      = "/"
            path_type = "Prefix"
            backend {
              service {
                name = rule.value.service != null ? rule.value.service : kubernetes_service.this[rule.value.app].metadata[0].name
                port { number = rule.value.port }
              }
            }
          }
        }
      }
    }
  }
}

locals {
  output_hosts = concat(
    flatten([for srv in local.services : [for p in srv.ports : {
      key  = "${srv.app}-${p}"
      host = "${srv.srv}.${var.namespace}.svc.${var.cluster_domain}"
      port = p
    }]]),
    [for srv in local.services : {
      key  = srv.app
      host = "${srv.srv}.${var.namespace}.svc.${var.cluster_domain}"
      port = srv.ports[0]
    } if length(srv.ports) == 1],
  )
}

output "service" {
  value = nonsensitive(zipmap(
    [for i in local.output_hosts : i.key],
    [for i in local.output_hosts : {
      host     = i.host
      port     = i.port
      hostport = "${i.host}:${i.port}"
      addr     = "http://${i.host}:${i.port}"
    }]
  ))
}

output "domains" {
  value = nonsensitive(toset(var.hostmap[*].domain))
}

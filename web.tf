locals {
  _app_service = { for hm in var.hostmap : hm.app => hm... if hm.app != null }

  services = { for app, srvs in local._app_service : app => {
    app = app
    srv = "${app}-${random_string.suffix.result}"
    ports = [for srv in srvs : {
      app  = app
      srv  = "${app}-${random_string.suffix.result}"
      port = srv.port
    }]
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
        name = "http-${port.value.port}"
        port = port.value.port
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
}

resource "kubernetes_ingress_v1" "this" {
  metadata {
    namespace = var.namespace
    name      = "${local.readable_identifier}-${random_string.suffix.result}"
    annotations = merge({
      "cert-manager.io/${provider::corefunc::str_kebab(var.issuer.kind)}" = var.issuer.name
      "kubernetes.io/ingress.class"                                       = "traefik"
    }, local.middleware_annotations)
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
    [for p in concat([for srv in local.services : srv.ports]...) : {
      key  = "${p.app}-${p.port}"
      host = "${p.srv}.${var.namespace}.svc.cluster.local"
      port = p.port
    }],
    [for srv in local.services : {
      key  = srv.app
      host = "${srv.srv}.${var.namespace}.svc.cluster.local"
      port = srv.ports[0].port
    } if length(srv.ports) == 1],
  )
}

output "service" {
  value = nonsensitive({
    for i in local.output_hosts : i.key => {
      host     = i.host
      port     = i.port
      hostport = "${i.host}:${i.port}"
      addr     = "http://${i.host}:${i.port}"
    }
  })
}

output "domains" {
  value = nonsensitive(toset(var.hostmap[*].domain))
}

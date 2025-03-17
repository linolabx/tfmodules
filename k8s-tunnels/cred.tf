resource "kubernetes_role_v1" "this" {
  metadata {
    name      = "tf-port-forward-${random_string.suffix.result}"
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods/portforward"]
    verbs      = ["get", "create"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "list"]
  }
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = "tf-port-forward-${random_string.suffix.result}"
    namespace = var.namespace
  }
}

resource "kubernetes_role_binding" "this" {
  metadata {
    name      = "tf-port-forward-${random_string.suffix.result}"
    namespace = var.namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.this.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = var.namespace
  }
}

resource "kubernetes_secret" "this" {
  metadata {
    name      = "tf-port-forward-${random_string.suffix.result}"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.this.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  wait_for_service_account_token = true
}

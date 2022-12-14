resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.16.10"

  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true

  values = [
    file("${path.module}/manifests/argo-cm.yaml")
  ]

  set {
    name  = "server.config.url"
    value = "https://argocd.${var.ingress_domain}"
  }

  set_sensitive {
    name  = "configs.secret.extra.oidc\\.keycloak\\.clientSecret"
    value = var.oidc_key
  }

  set {
    name  = "server.certificate.domain"
    value = "argocd.${var.ingress_domain}"
  }

  set {
    name  = "server.ingress.hosts[0]"
    value = "argocd.${var.ingress_domain}"
  }

  set {
    name  = "server.ingress.tls[0].hosts[0]"
    value = "argocd.${var.ingress_domain}"
  }
}

resource "helm_release" "argocd_apps" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "0.0.1"

  name       = "argo-apps"
  namespace  = "argocd"
  depends_on = [helm_release.argocd]

  values = [
    file("${path.module}/manifests/applications.yaml")
  ]
}

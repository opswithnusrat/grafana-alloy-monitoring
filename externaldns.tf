resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "external-dns"
  version    = "1.14.2"
  create_namespace = true

  values = [templatefile("${path.module}/values.yaml", {
    domain_filter = var.domain_name
    zone_id       = var.route53_zone_id
  })]
}



###############################################
# Cert Manager Configuration
###############################################



resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  version    = "v1.14.2"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = yamldecode(templatefile("${path.module}/cluster-issuer.yaml", {
    email = var.email
  }))
}

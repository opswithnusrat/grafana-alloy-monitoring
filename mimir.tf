
# # # # ----------------------------------------------
# # # # Load IAM Policy for mimir with IAM roles
# # # # ----------------------------------------------

data "aws_iam_policy_document" "mimir_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_role" "mimir" {
  name               = "mimir-pod-identity-role"
  assume_role_policy = data.aws_iam_policy_document.mimir_assume_role_policy.json
}

resource "aws_iam_policy" "mimir" {
  name   = "mimir-policy"
  policy = file("${path.module}/menifest/mimir/mimir.json")
}

resource "aws_iam_role_policy_attachment" "mimir_attach" {
  role       = aws_iam_role.mimir.name
  policy_arn = aws_iam_policy.mimir.arn
}

# ----------------------------------------------
# Pod Identity Association for mimir SA
# ----------------------------------------------

resource "aws_eks_pod_identity_association" "mimir" {
  cluster_name    = var.cluster_name
  namespace       = "mimir"        
  service_account = "mimir-sa"
  role_arn        = aws_iam_role.mimir.arn
}

# # # ###############################################################################
# # # # mimir  Helm
# # # ###############################################################################


resource "helm_release" "mimir" {
  name       = "mimir"
  chart      = "mimir-distributed"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = "mimir"
  version    = "5.1.0"
  create_namespace = true

  values = [templatefile("${path.module}/manifest/mimir/values.yaml", {
    region               = var.aws_region
    sa_role_arn          = aws_iam_role.mimir.arn
    domain_name          = var.domain_name
    service_account_name = "mimir-sa"

  })]
}

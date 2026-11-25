# 1. Registrar a GitHub como emisor de confianza de pases digitales (OIDC)
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# 2. Trust Policy del rol PLAN (¿Quién puede simular cambios?)
data "aws_iam_policy_document" "github_plan_trust" {
  statement {
    sid     = "AllowGitHubActionsPlanOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repo}:pull_request",
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"
      ]
    }
  }
}

# 3. Trust Policy del rol DEPLOY (¿Quién puede desplegar de verdad?)
data "aws_iam_policy_document" "github_deploy_trust" {
  statement {
    sid     = "AllowGitHubActionsDeployOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

# 4. Crear los dos roles IAM (los "pases temporales")
resource "aws_iam_role" "github_plan" {
  name                 = "threatpulse-github-plan-role"
  assume_role_policy   = data.aws_iam_policy_document.github_plan_trust.json
  max_session_duration = 3600
}

resource "aws_iam_role" "github_deploy" {
  name                 = "threatpulse-github-deploy-role"
  assume_role_policy   = data.aws_iam_policy_document.github_deploy_trust.json
  max_session_duration = 3600
}

# 5. Permission Policy (¿Qué pueden hacer con el bucket de estado S3?)
data "aws_iam_policy_document" "tfstate_access" {
  statement {
    sid       = "AllowListStateBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.tfstate.arn]
  }

  statement {
    sid       = "AllowStateReadWrite"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/app/terraform.tfstate"]
  }

  statement {
    sid       = "AllowLockFileLifecycle"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.tfstate.arn}/app/terraform.tfstate.tflock"]
  }
}

# Guardar la política de permisos en AWS IAM
resource "aws_iam_policy" "tfstate_access" {
  name        = "threatpulse-tfstate-access-policy"
  description = "Privilegio mínimo para operar el estado remoto de ThreatPulse y su bloqueo nativo"
  policy      = data.aws_iam_policy_document.tfstate_access.json
}

# 6. Enganchar (attach) la política de permisos a ambos roles
resource "aws_iam_role_policy_attachment" "plan_tfstate" {
  role       = aws_iam_role.github_plan.name
  policy_arn = aws_iam_policy.tfstate_access.arn
}

resource "aws_iam_role_policy_attachment" "deploy_tfstate" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.tfstate_access.arn
}
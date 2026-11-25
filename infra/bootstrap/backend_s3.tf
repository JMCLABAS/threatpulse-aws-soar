# 1. El contenedor principal (bucket S3)
resource "aws_s3_bucket" "tfstate" {
  bucket = var.state_bucket_name

  # Seguro anti-borrado: Terraform bloqueará cualquier intento accidental de destruir este bucket
  lifecycle {
    prevent_destroy = true
  }
}

# 2. Bloqueo total de acceso público (los 4 cerrojos de AWS cerrados)
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Versionado: guarda un historial de cada cambio del archivo de estado
resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 4. Cifrado en reposo (SSE-S3 / AES-256): cifra los archivos automáticamente en disco (0 €)
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 5. Regla de seguridad (JSON generado por Terraform): prohíbe tráfico sin cifrar (HTTP)
data "aws_iam_policy_document" "tfstate_enforce_tls" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.tfstate.arn,
      "${aws_s3_bucket.tfstate.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Conecta la regla JSON anterior con nuestro bucket
resource "aws_s3_bucket_policy" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  policy = data.aws_iam_policy_document.tfstate_enforce_tls.json
}
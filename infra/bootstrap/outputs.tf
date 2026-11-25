output "state_bucket_name" {
  description = "Nombre del bucket S3 donde se guardará el estado de infra/app"
  value       = aws_s3_bucket.tfstate.bucket
}

output "github_plan_role_arn" {
  description = "ARN del rol OIDC de solo lectura para Pull Requests"
  value       = aws_iam_role.github_plan.arn
}

output "github_deploy_role_arn" {
  description = "ARN del rol OIDC de despliegue exclusivo para la rama main"
  value       = aws_iam_role.github_deploy.arn
}
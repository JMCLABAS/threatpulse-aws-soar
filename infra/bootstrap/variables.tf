variable "aws_region" {
  description = "Región de AWS donde se crearán los recursos de bootstrap"
  type        = string
  default     = "eu-north-1"
}

variable "github_owner" {
  description = "Tu nombre de usuario exacto en GitHub (sensible a mayúsculas)"
  type        = string
}

variable "github_repo" {
  description = "Nombre exacto del repositorio en GitHub"
  type        = string
  default     = "threatpulse-aws-soar"
}

variable "state_bucket_name" {
  description = "Nombre globalmente único para el bucket S3 del estado de Terraform"
  type        = string
}
output "db_password_secret_arn" {
  description = "ARN du secret pour le mot de passe de la base de données"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "admin_credentials_secret_arn" {
  description = "ARN du secret pour les credentials admin"
  value       = aws_secretsmanager_secret.admin_credentials.arn
}

output "db_config_secret_arn" {
  description = "ARN du secret pour la configuration de la base de données"
  value       = aws_secretsmanager_secret.db_config.arn
}

output "all_secret_arns" {
  description = "Liste de tous les ARNs des secrets"
  value = [
    aws_secretsmanager_secret.db_password.arn,
    aws_secretsmanager_secret.admin_credentials.arn,
    aws_secretsmanager_secret.db_config.arn
  ]
}
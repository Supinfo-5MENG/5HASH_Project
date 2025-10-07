# Secret pour le mot de passe de la base de données
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-${var.environment}-db-password"
  description             = "Database password for ${var.project_name}"
  recovery_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-password"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = var.db_password
}

# Secret pour les credentials de l'admin PrestaShop
resource "aws_secretsmanager_secret" "admin_credentials" {
  name                    = "${var.project_name}-${var.environment}-admin-credentials"
  description             = "Admin credentials for ${var.project_name}"
  recovery_window_in_days = 7

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-admin-credentials"
  })
}

resource "aws_secretsmanager_secret_version" "admin_credentials" {
  secret_id = aws_secretsmanager_secret.admin_credentials.id
  secret_string = jsonencode({
    admin_email    = var.admin_email
    admin_password = var.admin_password
  })
}

# Secret pour toutes les informations de la base de données
resource "aws_secretsmanager_secret" "db_config" {
  name                    = "${var.project_name}-${var.environment}-db-config"
  description             = "Database configuration for ${var.project_name}"
  recovery_window_in_days = 0

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-config"
  })
}

resource "aws_secretsmanager_secret_version" "db_config" {
  secret_id = aws_secretsmanager_secret.db_config.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_address
    port     = var.db_port
    dbname   = var.db_name
  })
}
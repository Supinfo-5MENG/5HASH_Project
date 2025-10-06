output "db_instance_id" {
  description = "ID de l'instance RDS"
  value       = aws_db_instance.main.id
}

output "db_instance_address" {
  description = "Adresse de l'instance RDS"
  value       = aws_db_instance.main.address
}

output "db_instance_endpoint" {
  description = "Endpoint de l'instance RDS"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "db_instance_port" {
  description = "Port de l'instance RDS"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "Nom de la base de données"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "Nom d'utilisateur de la base de données"
  value       = aws_db_instance.main.username
  sensitive   = true
}
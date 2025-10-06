output "efs_id" {
  description = "ID du système de fichiers EFS"
  value       = aws_efs_file_system.main.id
}

output "efs_arn" {
  description = "ARN du système de fichiers EFS"
  value       = aws_efs_file_system.main.arn
}

output "efs_dns_name" {
  description = "DNS name du système de fichiers EFS"
  value       = aws_efs_file_system.main.dns_name
}
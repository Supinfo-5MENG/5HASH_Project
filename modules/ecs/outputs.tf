output "ecs_cluster_id" {
  description = "ID du cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN du cluster ECS"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_service_id" {
  description = "ID du service ECS"
  value       = aws_ecs_service.main.id
}

output "ecs_service_name" {
  description = "Nom du service ECS"
  value       = aws_ecs_service.main.name
}

output "ecs_task_definition_arn" {
  description = "ARN de la task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "cloudwatch_log_group_name" {
  description = "Nom du log group CloudWatch"
  value       = aws_cloudwatch_log_group.main.name
}
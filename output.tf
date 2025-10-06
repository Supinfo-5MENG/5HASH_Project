output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "load_balancer_url" {
  description = "URL to access PrestaShop"
  value       = "http://${module.alb.alb_dns_name}"
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "database_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "efs_file_system_id" {
  description = "EFS file system ID"
  value       = module.efs.efs_id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.ecs_service_name
}
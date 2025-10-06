output "alb_security_group_id" {
  description = "ID du security group ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID du security group ECS"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "ID du security group RDS"
  value       = aws_security_group.rds.id
}

output "efs_security_group_id" {
  description = "ID du security group EFS"
  value       = aws_security_group.efs.id
}
output "alb_id" {
  description = "ID de l'Application Load Balancer"
  value       = aws_lb.main.id
}

output "alb_arn" {
  description = "ARN de l'Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "DNS name de l'Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN du target group"
  value       = aws_lb_target_group.main.arn
}

output "listener_arn" {
  description = "ARN du listener"
  value       = aws_lb_listener.main.arn
}
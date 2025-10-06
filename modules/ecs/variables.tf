variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des IDs des subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du security group pour ECS"
  type        = string
}

variable "target_group_arn" {
  description = "ARN du target group"
  type        = string
}

variable "ecs_cpu" {
  description = "CPU pour la tâche ECS"
  type        = string
}

variable "ecs_memory" {
  description = "Mémoire pour la tâche ECS"
  type        = string
}

variable "desired_count" {
  description = "Nombre d'instances désirées"
  type        = number
}

variable "prestashop_image" {
  description = "Image Docker PrestaShop"
  type        = string
}

variable "log_retention_days" {
  description = "Rétention des logs en jours"
  type        = number
}

variable "efs_id" {
  description = "ID du système de fichiers EFS"
  type        = string
}

variable "db_address" {
  description = "Adresse de l'instance RDS"
  type        = string
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

variable "alb_dns_name" {
  description = "DNS name de l'ALB"
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN du listener ALB"
  type        = string
}

variable "efs_mount_targets" {
  description = "Mount targets EFS pour dépendance"
  type        = any
}

variable "common_tags" {
  description = "Tags communs à appliquer"
  type        = map(string)
}
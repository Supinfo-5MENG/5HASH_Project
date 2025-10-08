variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "prestashop"
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Stockage alloué pour RDS (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Version MySQL"
  type        = string
  default     = "8.0"
}

variable "db_username" {
  description = "Nom d'utilisateur de la base de données"
  type        = string
  default     = "prestashop_user"
  sensitive   = true
}

variable "db_password" {
  description = "Mot de passe de la base de données"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "prestashop"
}

variable "admin_email" {
  description = "Email de l'administrateur PrestaShop"
  type        = string
  default     = "admin@example.com"
  sensitive   = true
}

variable "admin_password" {
  description = "Mot de passe de l'administrateur PrestaShop"
  type        = string
  sensitive   = true
}

variable "ecs_cpu" {
  description = "CPU pour la tâche ECS"
  type        = string
  default     = "512"
}

variable "ecs_memory" {
  description = "Mémoire pour la tâche ECS"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Nombre d'instances désirées"
  type        = number
  default     = 2
}

variable "prestashop_image" {
  description = "Image Docker PrestaShop"
  type        = string
  default     = "prestashop/prestashop:latest"
}

variable "log_retention_days" {
  description = "Rétention des logs en jours"
  type        = number
  default     = 7
}
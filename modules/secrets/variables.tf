variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
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

variable "db_address" {
  description = "Adresse de l'instance RDS"
  type        = string
}

variable "db_port" {
  description = "Port de l'instance RDS"
  type        = number
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "admin_email" {
  description = "Email de l'administrateur PrestaShop"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Mot de passe de l'administrateur PrestaShop"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Tags communs à appliquer"
  type        = map(string)
}
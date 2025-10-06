variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des IDs des subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du security group pour RDS"
  type        = string
}

variable "db_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
}

variable "db_allocated_storage" {
  description = "Stockage alloué pour RDS (GB)"
  type        = number
}

variable "db_engine_version" {
  description = "Version MySQL"
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

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
}

variable "common_tags" {
  description = "Tags communs à appliquer"
  type        = map(string)
}
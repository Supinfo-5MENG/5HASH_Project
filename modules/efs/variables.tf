variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des IDs des subnets"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du security group pour EFS"
  type        = string
}

variable "common_tags" {
  description = "Tags communs à appliquer"
  type        = map(string)
}
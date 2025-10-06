variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "common_tags" {
  description = "Tags communs à appliquer"
  type        = map(string)
}
output "vpc_id" {
  description = "ID du VPC par défaut"
  value       = data.aws_vpc.default.id
}

output "subnet_ids" {
  description = "Liste des IDs des subnets"
  value       = data.aws_subnets.default.ids
}
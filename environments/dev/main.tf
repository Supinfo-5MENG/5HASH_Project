terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.13.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "networking" {
  source = "../../modules/networking"
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  vpc_id       = module.networking.vpc_id
  common_tags  = local.common_tags
}

module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.subnet_ids
  security_group_id = module.security.alb_security_group_id
  common_tags       = local.common_tags
}

module "efs" {
  source = "../../modules/efs"

  project_name      = var.project_name
  subnet_ids        = module.networking.subnet_ids
  security_group_id = module.security.efs_security_group_id
  common_tags       = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  project_name         = var.project_name
  subnet_ids           = module.networking.subnet_ids
  security_group_id    = module.security.rds_security_group_id
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  db_username          = var.db_username
  db_password          = var.db_password
  db_name              = var.db_name
  common_tags          = local.common_tags
}

module "secrets" {
  source = "../../modules/secrets"

  project_name   = var.project_name
  environment    = var.environment
  db_username    = var.db_username
  db_password    = var.db_password
  db_address     = module.rds.db_instance_address
  db_port        = module.rds.db_instance_port
  db_name        = module.rds.db_instance_name
  admin_email    = var.admin_email
  admin_password = var.admin_password
  common_tags    = local.common_tags

  depends_on = [module.rds]
}

module "ecs" {
  source = "../../modules/ecs"

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  subnet_ids                    = module.networking.subnet_ids
  security_group_id             = module.security.ecs_security_group_id
  target_group_arn              = module.alb.target_group_arn
  ecs_cpu                       = var.ecs_cpu
  ecs_memory                    = var.ecs_memory
  desired_count                 = var.desired_count
  prestashop_image              = var.prestashop_image
  log_retention_days            = var.log_retention_days
  efs_id                        = module.efs.efs_id
  db_address                    = module.rds.db_instance_address
  db_name                       = module.rds.db_instance_name
  db_username                   = module.rds.db_instance_username
  alb_dns_name                  = module.alb.alb_dns_name
  alb_listener_arn              = module.alb.listener_arn
  efs_mount_targets             = module.efs
  db_password_secret_arn        = module.secrets.db_password_secret_arn
  admin_credentials_secret_arn  = module.secrets.admin_credentials_secret_arn
  secret_arns                   = module.secrets.all_secret_arns
  common_tags                   = local.common_tags

  depends_on = [
    module.rds,
    module.alb,
    module.efs,
    module.secrets
  ]
}
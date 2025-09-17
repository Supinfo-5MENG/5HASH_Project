provider "aws" {
  region = var.provider_region
}

# Définit une tâche (modèle) qui sera utilisé par l'ECS pour déployer des conteneurs
# Equivalent à un docker-compose qu'on déploie sur n'importe quelle machine
resource "aws_ecs_task_definition" "prestashop_task_definition" {
  family       = "prestashop-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu          = "512"
  memory       = "1024"
  container_definitions = <<DEFINITION
  [
    {
      "name" : "prestashop",
      "image" : "prestashop/prestashop:latest",
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80,
          "protocol" : "tcp"
        }
      ],
      "environment" : [
        { "name" : "PS_INSTALL_AUTO", "value" : "1" },
        { "name" : "PS_DEMO_MODE", "value" : "1" },
        { "name" : "PS_DEV_MODE", "value" : "1" }
      ]
    }
  ]
  DEFINITION
}
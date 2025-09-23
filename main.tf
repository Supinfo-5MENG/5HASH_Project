provider "aws" {
  region = var.provider_region
}

# VPC par défaut
data "aws_vpc" "default" {
  default = true
}

# Sous réseaux du VPC par défaut
data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Groupe de sécurité du RDS
resource "aws_security_group" "rds_sg" {
  name = "prestashop-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.prestashop_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Groupe de sécurité pour exposer le port 80 du service
resource "aws_security_group" "prestashop_sg" {
  name = "prestashop-sg"
  description = "Autorise le traffic HTTP"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS MySQL
resource "aws_db_subnet_group" "prestashop" {
  name = "prestashop-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "prestashop" {
  identifier = "prestashop-db"
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  username = "rootusername"
  password = "rootpassword"
  db_name = "prestashop"
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.prestashop.name
  publicly_accessible = false
}

# Configuration du Load Balancer
# Groupe de sécurité
resource "aws_security_group" "alb_sg" {
  name = "prestashop-alb-sg"
  description = "Autorise HTTP vers ALB"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "prestashop" {
  name = "prestashop-alb"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "prestashop" {
  name = "prestashop-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path = "/"
    matcher = "200-399"
    interval = 30
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

# Écouteur HTTP
resource "aws_lb_listener" "prestashop" {
  load_balancer_arn = aws_lb.prestashop.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prestashop.arn
  }
}

# Cluster ECS
resource "aws_ecs_cluster" "prestashop" {
  name = "prestashop-cluster"
}

# Gestion du filesystem pour l'initialisation de prestashop
resource "aws_efs_file_system" "prestashop" {
  creation_token = "prestashop-efs"
  performance_mode = "generalPurpose"
  encrypted = true
}

# Point de montage dans chaque groupe de sécurité pour que Fargate puisse monter me volume dans n'importe quel AZ
resource "aws_efs_mount_target" "prestashop" {
  for_each = toset(data.aws_subnets.default.ids)

  file_system_id = aws_efs_file_system.prestashop.id
  subnet_id      = each.value
  security_groups = [aws_security_group.prestashop_sg.id]
}

# Définit une tâche (modèle) qui sera utilisé par l'ECS pour déployer des conteneurs
# Equivalent à un docker-compose qu'on déploie sur n'importe quelle machine
resource "aws_ecs_task_definition" "prestashop" {
  family       = "prestashop-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu          = "512"
  memory       = "1024"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "prestashop-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.prestashop.id
      transit_encryption = "ENABLED"
    }
  }

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
        { "name": "DB_SERVER", "value": "${aws_db_instance.prestashop.address}" },
        { "name": "DB_NAME", "value": "${aws_db_instance.prestashop.db_name}" },
        { "name": "DB_USER", "value": "${aws_db_instance.prestashop.username}" },
        { "name": "DB_PASSWD", "value": "${aws_db_instance.prestashop.password}" },
        { "name": "PS_INSTALL_AUTO", "value": "1" },
        { "name": "PS_DEMO_MODE", "value": "1" },
        { "name": "PS_DEV_MODE", "value": "1" },
        { "name": "PS_DOMAIN", "value": "${aws_lb.prestashop.dns_name}" }
      ],
      "mountPoints": [
        {
          "sourceVolume": "prestashop-data",
          "containerPath": "/var/www/html",
          "readOnly": false
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/prestashop",
          "awslogs-region": "${var.provider_region}",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
  DEFINITION
}

# Role IAM pour écrire les logs
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Groupe de journaux
resource "aws_cloudwatch_log_group" "prestashop" {
  name              = "/ecs/prestashop"
  retention_in_days = 7
}

# Service ECS
resource "aws_ecs_service" "prestashop" {
  name = "prestashop-service"
  cluster = aws_ecs_cluster.prestashop.id
  task_definition = aws_ecs_task_definition.prestashop.arn
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.prestashop_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prestashop.arn
    container_name = "prestashop"
    container_port = 80
  }

  depends_on = [
    aws_db_instance.prestashop,
    aws_lb_listener.prestashop
  ]
}
provider "aws" {
  region = "ap-south-1"
}

#########################
# ECS Cluster
#########################

resource "aws_ecs_cluster" "main" {
  name = "application-cluster"
}

#########################
# CloudWatch Log Groups
#########################

resource "aws_cloudwatch_log_group" "dev" {
  name              = "/ecs/dev-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "prod" {
  name              = "/ecs/prod-app"
  retention_in_days = 30
}

#########################
# ECS Task Execution Role
#########################

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

#########################
# DEV TASK DEFINITION
#########################

resource "aws_ecs_task_definition" "dev" {
  family                   = "dev-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "1024"   # 1 vCPU
  memory = "4096"   # 4 GB

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "dev-container"
      image     = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/dev-app:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.dev.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

#########################
# PROD TASK DEFINITION
#########################

resource "aws_ecs_task_definition" "prod" {
  family                   = "prod-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = "2048"   # 2 vCPU
  memory = "4096"   # 4 GB

  execution_role_arn = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "prod-container"
      image     = "123456789012.dkr.ecr.ap-south-1.amazonaws.com/prod-app:latest"
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.prod.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

#########################
# DEV ECS SERVICE
#########################

resource "aws_ecs_service" "dev" {
  name            = "dev-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.dev.arn

  desired_count = 4
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
    security_groups  = ["sg-xxxxxxxx"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = "arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/dev-tg/xxxxxxxx"
    container_name   = "dev-container"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy
  ]
}

#########################
# PROD ECS SERVICE
#########################

resource "aws_ecs_service" "prod" {
  name            = "prod-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prod.arn

  desired_count = 4
  launch_type   = "FARGATE"

  network_configuration {
    subnets          = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
    security_groups  = ["sg-xxxxxxxx"]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = "arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/prod-tg/xxxxxxxx"
    container_name   = "prod-container"
    container_port   = 8080
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution_policy
  ]
}
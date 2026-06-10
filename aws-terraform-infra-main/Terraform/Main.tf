# ==============================================================================
# 1. NETWORKING & EDGE SECURITY (VPC, Subnets, IGW, NAT, Route 53, CloudFront)
# ==============================================================================

resource "aws_vpc" "finovate_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "Finovate-VPC" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.finovate_vpc.id
  tags   = { Name = "Finovate-IGW" }
}

# Public Subnet (ap-south-1a) - Houses NAT Gateway and OpenVPN
resource "aws_subnet" "public_1a" {
  vpc_id            = aws_vpc.finovate_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = var.availability_zones[0]
  tags              = { Name = "Finovate-Public-Subnet-1a" }
}

# Elastic IP for NAT
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# NAT Gateway for Private Subnets internet access
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1a.id
  tags          = { Name = "Finovate-NAT-Gateway" }
}

# Private Subnets across AZ-1a and AZ-1b for ECS, RDS, Inference & Redis
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.finovate_vpc.id
  cidr_block        = "10.10.10.0/24"
  availability_zone = var.availability_zones[0]
  tags              = { Name = "Finovate-Private-Subnet-1a" }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.finovate_vpc.id
  cidr_block        = "10.10.20.0/24"
  availability_zone = var.availability_zones[1]
  tags              = { Name = "Finovate-Private-Subnet-1b" }
}

# Route53 & Edge Delivery Routing
resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_wafv2_web_acl" "waf" {
  name        = "Finovate-WAF"
  scope       = "CLOUDFRONT"
  description = "Protects global front doors"
  
  default_action {
    allow {}
  }
  
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "FinovateWAFMetric"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  web_acl_id = aws_wafv2_web_acl.waf.arn

  origin {
    domain_name = aws_lb.alb_prod.dns_name
    origin_id   = "ALB-PROD"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "ALB-PROD"
    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ==============================================================================
# 2. LOAD BALANCERS & COMPUTE LAYER (ALB, ECS Cluster, Fargate Tasks)
# ==============================================================================

# Public-facing Application Load Balancers routing traffic down to tasks
resource "aws_lb" "alb_prod" {
  name               = "ALB-PROD"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_1a.id, aws_subnet.private_1b.id] # Multi-AZ placement requirement
}

resource "aws_lb" "alb_dev" {
  name               = "ALB-DEV"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_1a.id, aws_subnet.private_1b.id]
}

# Main Compute Engine Cluster
resource "aws_ecs_cluster" "main_cluster" {
  name = "Finovate-ECS-Cluster"
}

# Task Definitions simulating Service 1-4 deployment footprints
resource "aws_ecs_task_definition" "prod_tasks" {
  family                   = "finovate-prod-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "service-container"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [{ containerPort = 80, hostPort = 80 }]
    }
  ])
}

# ==============================================================================
# 3. DATABASE, CACHE, & ACCELERATION (RDS Multi-AZ, Elasticache, G6 Inference)
# ==============================================================================

resource "aws_db_subnet_group" "rds_subnets" {
  name       = "finovate-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1b.id]
}

# PostgreSQL Database Architecture with Multi-AZ Replication Standby
resource "aws_db_instance" "postgres" {
  identifier             = "finovate-postgres"
  allocated_storage      = 500
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.m7i.xlarge"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnets.name
  multi_az               = true
  skip_final_snapshot    = true
  username               = "dbadmin"
  password               = aws_secretsmanager_secret_version.db_pass_val.secret_string
}

# Redis In-Memory Cache Cluster
resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "redis-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id]
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "finovate-redis"
  engine               = "redis"
  node_type            = "cache.m7g.large"
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  parameter_group_name = "default.redis7"
}

# EC2 Dedicated G6 GPU Node Instance utilized for Inference Processing (L4 Tensor Core)
resource "aws_instance" "inference_node" {
  ami           = "ami-0abcd1234abcd1234" # Deep Learning AMI GPU PyTorch
  instance_type = "g6.xlarge"
  subnet_id     = aws_subnet.private_1a.id

  tags = { Name = "Inference-Engine-L4" }
}

# ==============================================================================
# 4. CI/CD AUTOMATION PIPELINE (ECR, CodePipeline, CodeBuild, CodeDeploy)
# ==============================================================================

resource "aws_ecr_repository" "app_repo" {
  name                 = "finovate-app-repo"
  image_tag_mutability = "MUTABLE"
}

resource "aws_codepipeline" "pipeline" {
  name     = "Finovate-Deployment-Pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration    = { Branch = "main", RepositoryName = "finovate-core" }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration    = { ProjectName = aws_codebuild_project.builder.name }
    }
  }
}

resource "aws_codebuild_project" "builder" {
  name         = "Finovate-CodeBuild"
  service_role = aws_iam_role.build_role.arn

  artifacts { type = "CODEPIPELINE" }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true # Required to assemble Docker footprints
  }
  source { type = "CODEPIPELINE" }
}

# ==============================================================================
# 5. GOVERNANCE, OBSERVABILITY & SECURITY (CloudWatch, CloudTrail, SNS, Secrets)
# ==============================================================================

resource "aws_cloudtrail" "governance_trail" {
  name                          = "Finovate-CloudTrail"
  s3_bucket_name                = aws_s3_bucket.trail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/finovate-services"
  retention_in_days = 30
}

resource "aws_sns_topic" "alerts" {
  name = "Finovate-Alerting-Topic"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_secretsmanager_secret" "db_pass" {
  name = "prod-finovate-db-password"
}

resource "aws_secretsmanager_secret_version" "db_pass_val" {
  secret_id     = aws_secretsmanager_secret.db_pass.id
  secret_string = "SuperSecurePasswordString2026!"
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "pipeline_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name               = "FinovateECSExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role" "pipeline_role" {
  name               = "FinovatePipelineRole"
  assume_role_policy = data.aws_iam_policy_document.pipeline_assume_role.json
}

resource "aws_iam_role" "build_role" {
  name               = "FinovateBuildRole"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "codebuild_admin" {
  role       = aws_iam_role.build_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "pipeline_admin" {
  role       = aws_iam_role.pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# S3 buckets used by CI/CD pipeline and CloudTrail logs
resource "aws_s3_bucket" "pipeline_bucket" {
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Finovate-Pipeline-Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_block" {
  bucket                  = aws_s3_bucket.pipeline_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "trail_logs" {
  acl           = "private"
  force_destroy = true

  tags = {
    Name = "Finovate-CloudTrail-Logs"
  }
}

resource "aws_s3_bucket_public_access_block" "trail_logs_block" {
  bucket                  = aws_s3_bucket.trail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

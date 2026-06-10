########################################
# AWS Configuration
########################################

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

########################################
# ECS Cluster
########################################

variable "ecs_cluster_name" {
  description = "ECS Cluster Name"
  type        = string
  default     = "application-cluster"
}

########################################
# DEV Configuration
########################################

variable "dev_service_name" {
  description = "DEV ECS Service Name"
  type        = string
  default     = "dev-service"
}

variable "dev_task_family" {
  description = "DEV Task Definition Family"
  type        = string
  default     = "dev-app"
}

variable "dev_cpu" {
  description = "DEV Task CPU"
  type        = number
  default     = 1024
}

variable "dev_memory" {
  description = "DEV Task Memory (MB)"
  type        = number
  default     = 4096
}

variable "dev_desired_count" {
  description = "DEV Desired Task Count"
  type        = number
  default     = 4
}

variable "dev_container_name" {
  description = "DEV Container Name"
  type        = string
  default     = "dev-container"
}

variable "dev_container_port" {
  description = "DEV Container Port"
  type        = number
  default     = 8080
}

variable "dev_image" {
  description = "DEV ECR Image URI"
  type        = string
}

variable "dev_target_group_arn" {
  description = "DEV ALB Target Group ARN"
  type        = string
}

########################################
# PROD Configuration
########################################

variable "prod_service_name" {
  description = "PROD ECS Service Name"
  type        = string
  default     = "prod-service"
}

variable "prod_task_family" {
  description = "PROD Task Definition Family"
  type        = string
  default     = "prod-app"
}

variable "prod_cpu" {
  description = "PROD Task CPU"
  type        = number
  default     = 2048
}

variable "prod_memory" {
  description = "PROD Task Memory (MB)"
  type        = number
  default     = 4096
}

variable "prod_desired_count" {
  description = "PROD Desired Task Count"
  type        = number
  default     = 4
}

variable "prod_container_name" {
  description = "PROD Container Name"
  type        = string
  default     = "prod-container"
}

variable "prod_container_port" {
  description = "PROD Container Port"
  type        = number
  default     = 8080
}

variable "prod_image" {
  description = "PROD ECR Image URI"
  type        = string
}

variable "prod_target_group_arn" {
  description = "PROD ALB Target Group ARN"
  type        = string
}

########################################
# Networking
########################################

variable "subnet_ids" {
  description = "Private Subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Group IDs"
  type        = list(string)
}

########################################
# CloudWatch Logs
########################################

variable "log_retention_days" {
  description = "CloudWatch Log Retention"
  type        = number
  default     = 30
}

########################################
# Tags
########################################

variable "common_tags" {
  description = "Common Tags"
  type        = map(string)

  default = {
    Project     = "Application"
    Environment = "Shared"
    ManagedBy   = "Terraform"
  }
}
# AWS Region
variable "aws_region" {
  description = "AWS Region where resources will be deployed"
  type        = string
  default     = "ap-south-1"
}

# VPC ID
variable "vpc_id" {
  description = "VPC ID where ALB and Target Group will be created"
  type        = string
}

# Public Subnets
variable "subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

# ALB Name
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "terraform-alb"
}

# Target Group Name
variable "target_group_name" {
  description = "Name of the Target Group"
  type        = string
  default     = "terraform-tg"
}

# Listener Port
variable "listener_port" {
  description = "ALB Listener Port"
  type        = number
  default     = 80
}

# Target Group Port
variable "target_group_port" {
  description = "Target Group Port"
  type        = number
  default     = 80
}

# Health Check Path
variable "health_check_path" {
  description = "Health check endpoint path"
  type        = string
  default     = "/"
}

# ALB Scheme
variable "internal" {
  description = "Whether the ALB is internal or internet-facing"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
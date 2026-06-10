# ALB Information
output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.alb.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  description = "Canonical Hosted Zone ID of the ALB"
  value       = aws_lb.alb.zone_id
}

# Security Group
output "alb_security_group_id" {
  description = "Security Group ID attached to the ALB"
  value       = aws_security_group.alb_sg.id
}

# Target Group
output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.tg.arn
}

output "target_group_name" {
  description = "Name of the Target Group"
  value       = aws_lb_target_group.tg.name
}

# Listener
output "http_listener_arn" {
  description = "ARN of the HTTP Listener"
  value       = aws_lb_listener.http_listener.arn
}
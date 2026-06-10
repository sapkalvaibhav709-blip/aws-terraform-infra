output "ec2_instance_id" {
  value = aws_instance.ec2_server.id
}

output "ec2_public_ip" {
  value = aws_instance.ec2_server.public_ip
}

output "ec2_private_ip" {
  value = aws_instance.ec2_server.private_ip
}

output "security_group_id" {
  value = aws_security_group.ec2_sg.id
}
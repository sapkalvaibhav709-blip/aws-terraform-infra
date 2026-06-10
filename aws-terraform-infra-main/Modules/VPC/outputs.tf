output "vpc_id" {
  value = aws_vpc.main.id
}

# Public Subnet Output
output "public_subnet_id" {
  value = aws_subnet.public_subnet.id
}

# Private Subnet Output
output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}
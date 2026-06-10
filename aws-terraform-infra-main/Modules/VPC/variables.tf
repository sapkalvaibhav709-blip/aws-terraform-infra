variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

# Public Subnet Variables
variable "public_subnet_cidr" {
  type = string
}

variable "public_availability_zone" {
  type = string
}

# Private Subnet Variables
variable "private_subnet_cidr" {
  type = string
}

variable "private_availability_zone" {
  type = string
}
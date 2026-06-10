variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "alert_email" {
  type    = string
  default = "admin@example.com"
}

variable "availability_zones" {
  type = list(string)

  default = [
    "ap-south-1a",
    "ap-south-1b"
  ]
}

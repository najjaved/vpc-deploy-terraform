variable "instance_type" {
  description = "Instance type for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.23.0/24", "10.0.24.0/24"]
}

# Declare varaibles for existing resources in AWS
data "aws_key_pair" "naj_key" {
  key_name = "naj-key"
}

# add AMI Data Source
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical (official Ubuntu AMI owner)
}
# Create a VPC with a CIDR block
resource "aws_vpc" "naj_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Najma-vpc"
  }
}

#********************************************************************************
# Add a public subnet resource
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.naj_vpc.id #associate subnet with the VPC created earlier
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # instances launched in this subnet will automatically receive public IP addresses
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public-subnet-naj"
  }
}

# Add an Internet Gateway (IGW) to provide Internet access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.naj_vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}

# Define a route table that directs outbound traffic to the IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.naj_vpc.id

  route {
    cidr_block = "0.0.0.0/0" #route defined sends all traffic (0.0.0.0/0) to the Internet Gateway
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate the Public Subnet with the Route Table. 
# This association ensures that instances in the public subnet follow the routing rules defined in the route table
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#********************************************************************************
# Add a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.naj_vpc.id #associate subnet with the VPC created earlier
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false   # No public IP for private subnet
  availability_zone       = "us-east-1b" 

  tags = {
    Name = "private-subnet-naj"
  }
}

# NAT Gateway requires an Elastic IP (EIP) to allow outbound internet access
resource "aws_eip" "nat_gw_ip" {
  domain = "vpc"

  tags = {
    Name = "NAT-Gateway-EIP"
  }
}

# Create a NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw_ip.id
  subnet_id     = aws_subnet.public_subnet.id  # the NAT Gateway will be placed in the public subnet to allow private subnet instances to access the internet

  tags = {
    Name = "NAT-Gateway"
  }
}

#Create a Route Table for the Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.naj_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate the PrivateRouteTable with the Private Subnet
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

#*********************************************************************
# Add a Security Group that allows SSH (port 22)
resource "aws_security_group" "new-security-group" {
  name        = "naj-security-group"
  description = "Security group that allows SSH connection"
  vpc_id      = aws_vpc.naj_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # allows inbound SSH access from any IP (0.0.0.0/0)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # allows all outbound traffic
  }
}

# Add EC2 instance that uses the security group
resource "aws_instance" "new-EC2-instance" {
  ami                         = data.aws_ami.ubuntu.id   #  "ami-0cb91c7de36eed2cb"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.new-security-group.id]
  subnet_id                   = aws_subnet.public_subnet.id  

  key_name                    = data.aws_key_pair.naj_key.key_name #use existing key in ohio region

  tags = {
    Name = "naj-instance-terrafrom"
  }
}


# Declare varaibles for existing resources in AWS
data "aws_key_pair" "naj_key" {
  key_name = "naj-key"
}

# add AMI Data Source
data "aws_ami" "ubuntu" {
  most_recent = true # select the latest Ubuntu 20.04 LTS Amazon Machine Image (AMI) from AWS

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] # wildcard (*) ensures that any newer AMI versions matching this name pattern will be included
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] # ensures the AMI has hardware-assisted virtualization (HVM)
  }

  owners = ["099720109477"] # belongs to Canonical, the official provider of Ubuntu AMIs
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
  cidr_block              = "10.0.41.0/24"
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
  cidr_block              = "10.0.42.0/24"
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
  instance_type               = var.instance_type # use variable defined in variables file
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.new-security-group.id]
  subnet_id                   = aws_subnet.public_subnet.id  

  key_name                    = data.aws_key_pair.naj_key.key_name #use existing key in N.Virginia region

  tags = {
    Name = "naj-instance-terrafrom"
  }
}

#******************** Deploy subnets in multiple Availability Zones ********************************
# Retrieve availability zones dynamically
data "aws_availability_zones" "available_zones" {}

# Define public subnets in two different availability zones
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs) # 2

  vpc_id            = aws_vpc.naj_vpc.id
  cidr_block        =var.public_subnet_cidrs[count.index]  # cidrsubnet(aws_vpc.naj_vpc.cidr_block, 4, count.index + 2)  # generate subnet CIDR blocks dynamically
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

#Define private subnets in two different availability zones
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
   
  vpc_id            = aws_vpc.naj_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index] # cidrsubnet(aws_vpc.naj_vpc.cidr_block, 4, count.index) # generate subnet CIDR blocks dynamically
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

#******************** deploy an EC2 instance as a bastion host ********************
resource "aws_instance" "bastion-host" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public_subnet.id 
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = data.aws_key_pair.naj_key.key_name

  tags = {
    Name = "naj-Bastion-Host"
  }
}
# Create a Security Group for the Bastion Host
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access from your trusted IP to bastion host"
  vpc_id      = aws_vpc.naj_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_ips 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "naj-Bastion-SG"
  }
}



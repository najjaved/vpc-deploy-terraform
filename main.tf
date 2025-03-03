# Create a VPC with a CIDR block
resource "aws_vpc" "naj_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Najma-vpc"
  }
}

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
    Name = "InternetGateway"
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




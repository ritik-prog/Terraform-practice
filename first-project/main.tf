# 0. Define Provider and region
provider "aws" {
  region = "us-east-1"
}

# 1. create a vpc
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "startedwith" = "terraform"
    Name          = "terraform-vpc"
  }
}

# 2. create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name            = "public_subnet_terraform"
    "public_subnet" = "public_subnet_terraform"
  }
}

# 3. create a private subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.terraform_vpc.id
  availability_zone       = "us-east-1b"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name             = "private_subnet_terraform"
    "private_subnet" = "private_subnet_terraform"
  }
}

# 4. create a IGW
resource "aws_internet_gateway" "igw_terraform" {
  vpc_id = aws_vpc.terraform_vpc.id
}

# 5. route table for public subnet 
resource "aws_route_table" "rt_terraform" {
  vpc_id = aws_vpc.terraform_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_terraform.id
  }
}

# 6. route table association with public
resource "aws_route_table_association" "rta_terraform" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt_terraform.id
}

# 7. create an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# 8. create a NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

# 9. create a route table for private subnet 
resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.terraform_vpc.id
}

# 10. add a route to the NAT Gateway in the private route table
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.rt_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# 11. associate private subnet with the route table
resource "aws_route_table_association" "rta_private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.rt_private.id
}

# 12. Create a security group for EC2 instance
resource "aws_security_group" "private_sg" {
  name_prefix = "private_sg_terraform"
  vpc_id      = aws_vpc.terraform_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 13. Launch an EC2 instance in the private subnet
resource "aws_instance" "private_ec2_terraform" {
  ami                    = "ami-0dfcb1ef8550277af"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "private_ec2_terraform"
  }
}

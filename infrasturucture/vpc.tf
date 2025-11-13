resource "aws_vpc" "production_secure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "transaction_project"
  }
}

resource "aws_subnet" "public_subnet_1" {
  availability_zone       = "us-west-1a"
  vpc_id                  = aws_vpc.production_secure_vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }
}

resource "aws_route_table" "public_subnet_1_route_table" {
  vpc_id = aws_vpc.production_secure_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_subnet_1_route_table"
  }
}

resource "aws_route_table_association" "public_subnet_1_route_table" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_subnet_1_route_table.id
}

resource "aws_subnet" "public_subnet_2" {
  availability_zone       = "us-west-1c"
  vpc_id                  = aws_vpc.production_secure_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}

resource "aws_route_table" "public_subnet_2_route_table" {
  vpc_id = aws_vpc.production_secure_vpc.id
}

resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_subnet_2_route_table.id

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.production_secure_vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_security_group" "production_security_group" {
  name        = "production_security_group"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.production_secure_vpc.id

  tags = {
    Name = "production_security_group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_" {
  security_group_id = aws_security_group.production_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 5439
  ip_protocol       = "tcp"
  to_port           = 5439
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.production_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# Create a VPC 
resource "aws_vpc" "redshift_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "redshift_project"
  }
}

# Create public_subnet
resource "aws_subnet" "public_subnet" {
  availability_zone = "us-west-1a"
  vpc_id            = aws_vpc.redshift_vpc.id
  cidr_block        = var.public_subnet_cidr

  tags = {
    Name = "public_subnet"
  }
}

# Create public route_table
resource "aws_route_table" "new_public_route_table" {
  vpc_id = aws_vpc.redshift_vpc.id

  route {
    cidr_block = var.internet_cidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "new_public_route_table"
  }
}

# Create an association 
resource "aws_route_table_association" "public_route_table" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.new_public_route_table.id
}


# Create private_subnet 
resource "aws_subnet" "private_subnet" {
  availability_zone = "us-west-1c"
  vpc_id            = aws_vpc.redshift_vpc.id
  cidr_block        = var.private_subnet_cidr

  tags = {
    Name = "private_subnet"
  }
}


# Create private route_table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.redshift_vpc.id
}

# Create an association 
resource "aws_route_table_association" "private_subnet" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id

}


# Create aws_internet_gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.redshift_vpc.id

  tags = {
    Name = "igw"
  }
}


# Create a security group
resource "aws_security_group" "redshift_security_group" {
  name        = "redshift_security_group"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      =  aws_vpc.redshift_vpc.id

  tags = {
    Name = "redshift_security_group"
  }
}
resource "aws_vpc_security_group_ingress_rule" "allow_" {
  security_group_id = aws_security_group.redshift_security_group.id
  cidr_ipv4         = var.internet_cidr
  from_port         = 5439
  ip_protocol       = "tcp"
  to_port           = 5439
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.redshift_security_group.id
  cidr_ipv4         = var.internet_cidr
  ip_protocol       = "-1"
}

# Create a Redshift Subnet Group
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "redshift-subnet-group"
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    environment = "Production"
  }
}

# Create IAM role
resource "aws_iam_role" "redshift_role" {
  name = "redshift_new_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "redshift"
  }
}

# Create a policy
resource "aws_iam_policy" "new_redshift_policy" {
  name = "new_redshift_policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListAllBuckets",
          "redshift:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "new_redshift_role_policy_attachment" {
  name       = "new_redshift_role_policy_attachment"
  roles      = [aws_iam_role.redshift_role.name]
  policy_arn = aws_iam_policy.new_redshift_policy.arn
}

resource "aws_redshift_cluster_iam_roles" "new_redshift_cluster_iam_roles" {
  cluster_identifier = aws_redshift_cluster.new_redshift_job.cluster_identifier
  iam_role_arns      = [aws_iam_role.redshift_role.arn]
}


resource "random_password" "password" {
  length  = 12
  special = false
  upper = true  
  numeric = true
}

resource "aws_ssm_parameter" "new_redshift_db_password" {
  name  = "new_redshift_db_password"
  type  = "String"
  value = random_password.password.result
  
}

resource "aws_redshift_parameter_group" "new_redshift_parameter_group" {
  name   = "new-redshift-parameter-group"
  family = "redshift-2.0"
  parameter {
    name  = "require_ssl"
    value = "false"
  }
}

#Create the cluster 
resource "aws_redshift_cluster" "new_redshift_job" {
  cluster_identifier  = "new-redshift-cluster"
  database_name       = "new_redshift_victordb"
  master_username     = "new_victor_job"
  master_password     = aws_ssm_parameter.new_redshift_db_password.value
  node_type           = "ra3.xlplus"
  cluster_type        = "multi-node"
  iam_roles           = [aws_iam_role.redshift_role.arn]
  number_of_nodes     = 2
  publicly_accessible = true
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift_subnet_group.name
  cluster_parameter_group_name = aws_redshift_parameter_group.new_redshift_parameter_group.name

}

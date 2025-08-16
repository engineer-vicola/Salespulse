resource "aws_iam_role" "redshift_role" {
  name = "redshift_new_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
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


resource "aws_iam_policy" "new_redshift_policy" {
  name   = "new_redshift_policy"
  path   = "/production/new_redshift_policy/"
  policy = data.aws_iam_policy_document.redshift_policy_document.json
}


resource "aws_iam_policy_attachment" "new_redshift_role_policy_attachment" {
  name       = "new_redshift_role_policy_attachment"
  roles      = [aws_iam_role.redshift_role.name]
  policy_arn = aws_iam_policy.new_redshift_policy.arn
}


resource "random_password" "password" {
  length  = 12
  special = false
  upper   = true
  numeric = true
}

resource "aws_ssm_parameter" "new_redshift_db_password" {
  name  = "/production/new_redshift_db_password"
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

resource "aws_redshift_cluster" "new_redshift_job" {
  cluster_identifier               = "new-redshift-cluster"
  database_name                    = "new_redshift_victordb"
  master_username                  = "new_victor_job"
  master_password                  = aws_ssm_parameter.new_redshift_db_password.value
  node_type                        = "ra3.xlplus"
  cluster_type                     = "multi-node"
  iam_roles                        = [aws_iam_role.redshift_role.arn]
  number_of_nodes                  = 2
  publicly_accessible              = true
  cluster_subnet_group_name        = aws_redshift_subnet_group.production_subnet_group.name
  cluster_parameter_group_name     = aws_redshift_parameter_group.new_redshift_parameter_group.name
  preferred_maintenance_window     = "sun:02:00-03:00"
  manual_snapshot_retention_period = 10
}

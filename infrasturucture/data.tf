data "aws_ssm_parameter" "new_redshift_db_username" {
  name  = "/production/new_redshift_db_username"
  type  = "String"
  value = "new_sales_job"
}

data "aws_iam_policy_document" "redshift_policy_document" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListAllBuckets",
    "redshift:*"]

    resources = [
      "arn:aws:s3:::*",
    ]
  }
}

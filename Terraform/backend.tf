terraform {
  backend "s3" {
    bucket = "redshift-project-state-file"
    key    = "redshift-project-state-file/terraform.tfstate"
    region = "us-west-1"
  }
}
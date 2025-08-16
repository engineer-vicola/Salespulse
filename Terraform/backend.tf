terraform {
  backend "s3" {
    bucket       = "data-project-state-file"
    key          = "/production/data-project-state-file.tfstate"
    use_lockfile = true
    region       = "us-west-1"
  }
}

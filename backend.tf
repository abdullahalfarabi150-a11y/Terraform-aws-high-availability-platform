terraform {
  backend "s3" {
    bucket       = "farabi-project2-terraform-state-641332413499"
    key          = "project2/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
terraform {
  backend "s3" {
    bucket  = "project-bedrock-tfstate-715398629827"
    key     = "project-bedrock/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

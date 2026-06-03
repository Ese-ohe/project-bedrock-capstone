variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name required by the capstone"
  type        = string
  default     = "project-bedrock-cluster"
}

variable "assets_bucket_name" {
  description = "S3 bucket for uploaded product assets"
  type        = string
  default     = "bedrock-assets-ese-715398629827"

}

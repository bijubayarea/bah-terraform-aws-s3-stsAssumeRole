# variable declarations

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "s3_buckets" {
    type = map
    default = {
        s3_allow  = "bah-bijubayarea-s3-public",
        s3_deny   = "bah-bijubayarea-s3-private"
    }
}
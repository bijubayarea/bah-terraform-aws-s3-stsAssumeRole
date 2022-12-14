# variable declarations

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

#variable "aws_account_ids" {
#    type  = map
#    default = {
#      user: "427234555883", 
#      owner: "427234555883"
#    }
#  }
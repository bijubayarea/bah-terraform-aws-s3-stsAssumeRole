
# Account ID
output "s3_owner_account_id" {
  value = data.aws_caller_identity.source.account_id
}

# Owner Role
output "assume_s3_owner_role_arn" {
  value = aws_iam_role.assume_s3_owner_role.arn
}
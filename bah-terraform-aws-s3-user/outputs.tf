
# s3_user AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY 
output "s3_user_secret_key" {
  value = aws_iam_access_key.s3_user.secret
  sensitive = true
}

output "s3_user_access_key" {
  value = aws_iam_access_key.s3_user.id
}

# s3_unauthorized AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY 
output "s3_unauthorized_user_secret_key" {
  value = aws_iam_access_key.s3_unauthorized.secret
  sensitive = true
}

output "s3_unauthorized_user_access_key" {
  value = aws_iam_access_key.s3_unauthorized.id
}

output "s3_user_arn" {
  value = aws_iam_user.s3_user.arn
}

output "s3_unauthorized_arn" {
  value = aws_iam_user.s3_unauthorized.arn
}

data "aws_caller_identity" "source" {
  provider = aws.Account
}


# IAM role for s3_owner
# only s3 user can assume this role
# s3_unauthorized user cannot assume this role
data "aws_iam_policy_document" "assume_s3_owner_role" {
  statement {

    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "AWS"
      #identifiers = ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:root"]
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:user/s3-user"]
    }

  }
}

# IAM role for S3 owner
resource "aws_iam_role" "assume_s3_owner_role" {
  name               = "s3-owner-role"
  assume_role_policy = data.aws_iam_policy_document.assume_s3_owner_role.json
}

# Resource Policy document for s3_owner
data "aws_iam_policy_document" "s3_read_policy_document" {
  statement {
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
    effect    = "Allow"
  }
  statement {
    actions   = [
      #"s3:*"
      "s3:Get*",
      "s3:List*"
      ]
    resources = [
      aws_s3_bucket.s3_public.arn,
      "${aws_s3_bucket.s3_public.arn}/*"]
    effect    = "Allow"
  }
}

# S3 Owner policy for S3 bucket
resource "aws_iam_policy" "s3_read_policy" {

  name   = "s3-read-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.s3_read_policy_document.json
}

# Attach IAM role to S3 resource policy
resource "aws_iam_role_policy_attachment" "s3_owner_role_attachment" {
  role       = aws_iam_role.assume_s3_owner_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}


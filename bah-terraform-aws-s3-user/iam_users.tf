# Create 2 users and s3_user and s3_unauthorized
resource "aws_iam_user" "s3_user" {
  name = "s3-user"
  path = "/"
}

resource "aws_iam_user" "s3_unauthorized" {
  name = "s3-unauthorized"
  path = "/"
}



resource "aws_iam_access_key" "s3_user" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_access_key" "s3_unauthorized" {
  user = aws_iam_user.s3_unauthorized.name
}




# create iam group user
resource "aws_iam_group" "s3_user_group" {
  name = "s3_user_group"
  path = "/"
}


# Associate s3_user to s3_user_group
resource "aws_iam_user_group_membership" "s3_user_memebership" {
  user = aws_iam_user.s3_user.name

  groups = [
    aws_iam_group.s3_user_group.name
  ]
}

# Associate s3_unauthorized to s3_user_group
resource "aws_iam_user_group_membership" "s3_unauthorized_memebership" {
  user = aws_iam_user.s3_unauthorized.name

  groups = [
    aws_iam_group.s3_user_group.name
  ]
}


data "aws_caller_identity" "source" {
  provider = aws.Account
}

# IAM policy document  for s3_user to assume s3_owner_role
# Both s3_user and s3_unauthorized can assusme s3_owner_read role
data "aws_iam_policy_document" "assume_s3_user_policy" {
  statement {

    actions   = ["sts:AssumeRole",
                 "iam:ListRoles"]
    effect    = "Allow"
    #resource  =  arn:aws:iam::OwnerAccount:role/OwnerReadRole
    resources  =  ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:role/s3-owner-role"]
  }

  statement {

    actions   = ["iam:ListRoles"]
    effect    = "Allow"
    #resource  =  arn:aws:iam::OwnerAccount:role/OwnerReadRole
    resources  =  ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:role/*"]
    
  }

}

# S3 read policy for S3 bucket
resource "aws_iam_policy" "assume_s3_user_policy" {

  name   = "s3-user-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.assume_s3_user_policy.json
}

# Attach s3_user_group to assume_s3_owner Read role
resource "aws_iam_group_policy_attachment" "assume_s3_user_attach" {
  group      = aws_iam_group.s3_user_group.name
  policy_arn = aws_iam_policy.assume_s3_user_policy.arn
}


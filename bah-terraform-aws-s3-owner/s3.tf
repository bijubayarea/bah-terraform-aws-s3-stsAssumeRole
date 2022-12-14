# Public S3 bucket
resource "aws_s3_bucket" "s3_public" {
  bucket        = var.s3_buckets["s3_allow"]
  force_destroy = true

  tags = {
    Name = "s3 bucket public"
    env  = "test"
  }
}

resource "aws_s3_bucket_acl" "s3_public_acl" {
  bucket = aws_s3_bucket.s3_public.id
  acl    = "private"
}


# Private S3 Bucket
resource "aws_s3_bucket" "s3_private" {
  bucket        = var.s3_buckets["s3_deny"]
  force_destroy = true

  tags = {
    Name = "s3 bucket private"
    env  = "test"
  }
}

resource "aws_s3_bucket_acl" "s3_private_acl" {
  bucket = aws_s3_bucket.s3_private.id
  acl    = "private"
}
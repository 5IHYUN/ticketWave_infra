variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "environment" {
  type        = string
  description = "The environment name (e.g. dev, prod)"
}

variable "force_destroy" {
  type        = bool
  description = "객체가 남아 있어도 버킷 삭제 허용 (생성·삭제 반복 환경용)"
  default     = false
}

variable "enable_cloudfront" {
  type        = bool
  description = "Whether to serve poster images through CloudFront with OAC"
  default     = false
}

resource "aws_s3_bucket" "poster_bucket" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "poster_bucket" {
  bucket = aws_s3_bucket.poster_bucket.id

  block_public_acls       = true
  block_public_policy     = var.enable_cloudfront
  ignore_public_acls      = true
  restrict_public_buckets = var.enable_cloudfront
}

resource "aws_cloudfront_origin_access_control" "poster_bucket" {
  count = var.enable_cloudfront ? 1 : 0

  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "poster_bucket" {
  count = var.enable_cloudfront ? 1 : 0

  enabled     = true
  comment     = "${var.bucket_name} poster CDN"
  price_class = "PriceClass_200"

  origin {
    domain_name              = aws_s3_bucket.poster_bucket.bucket_regional_domain_name
    origin_id                = "s3-${aws_s3_bucket.poster_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.poster_bucket[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.poster_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.bucket_name}-cdn"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_policy" "poster_bucket" {
  bucket     = aws_s3_bucket.poster_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.poster_bucket]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.enable_cloudfront ? [
        {
          Sid    = "AllowCloudFrontReadPosters"
          Effect = "Allow"
          Principal = {
            Service = "cloudfront.amazonaws.com"
          }
          Action   = "s3:GetObject"
          Resource = "${aws_s3_bucket.poster_bucket.arn}/posters/*"
          Condition = {
            StringEquals = {
              "AWS:SourceArn" = aws_cloudfront_distribution.poster_bucket[0].arn
            }
          }
        }
      ] : [],
      !var.enable_cloudfront ? [
        {
          Sid       = "AllowPublicReadPosters"
          Effect    = "Allow"
          Principal = "*"
          Action    = "s3:GetObject"
          Resource  = "${aws_s3_bucket.poster_bucket.arn}/posters/*"
        }
      ] : []
    )
  })
}

output "bucket_name" {
  value = aws_s3_bucket.poster_bucket.id
}

output "bucket_arn" {
  value = aws_s3_bucket.poster_bucket.arn
}

output "cloudfront_distribution_id" {
  value = var.enable_cloudfront ? aws_cloudfront_distribution.poster_bucket[0].id : null
}

output "cloudfront_domain_name" {
  value = var.enable_cloudfront ? aws_cloudfront_distribution.poster_bucket[0].domain_name : null
}

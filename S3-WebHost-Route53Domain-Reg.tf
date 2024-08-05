# Define AWS provider and region
provider "aws" {
  region = var.region # Define your AWS region in the variable section below
}

# Variables section
variable "domain_name" {
  default = "techconsultio.com" # Replace with your actual domain name
}

variable "region" {
  default = "us-west-2" # Replace with your preferred AWS region
}

# Create S3 Bucket for Static Website Hosting
resource "aws_s3_bucket" "webs3_static_website" {
  bucket = "webs3-${var.domain_name}-website" # Custom S3 bucket name with prefix webs3

  tags = {
    Name = "webs3-static-website"
  }
}

# Configure Public Access Block for S3 Bucket
resource "aws_s3_bucket_public_access_block" "webs3_static_website" {
  bucket = aws_s3_bucket.webs3_static_website.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# Configure Website Hosting for S3 Bucket
resource "aws_s3_bucket_website_configuration" "webs3_static_website" {
  bucket = aws_s3_bucket.webs3_static_website.id

  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

# Upload files to S3 Bucket from GitHub
resource "aws_s3_object" "webs3_index" {
  bucket = aws_s3_bucket.webs3_static_website.id
  key    = "index.html"
  source = "index.html" # Ensure the file is available locally in the same directory as your Terraform script
  acl    = "public-read"
}

# Upload other necessary files to S3 Bucket from GitHub
resource "aws_s3_object" "webs3_error" {
  bucket = aws_s3_bucket.webs3_static_website.id
  key    = "error.html"
  source = "error.html" # Ensure the file is available locally in the same directory as your Terraform script
  acl    = "public-read"
}

# Create Route 53 Zone for the domain
resource "aws_route53_zone" "webs3_main" {
  name = var.domain_name
}

# # Create ACM Certificate for the domain
# resource "aws_acm_certificate" "webs3_main" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   tags = {
#     Name = "webs3-main-certificate"
#   }
# }

# # Create Route 53 Record for Domain Validation
# resource "aws_route53_record" "webs3_certificate_validation" {
#   for_each = { for dvo in aws_acm_certificate.webs3_main.domain_validation_options : dvo.domain_name => dvo }

#   zone_id = aws_route53_zone.webs3_main.id
#   name    = each.value.resource_record_name
#   type    = each.value.resource_record_type
#   ttl     = 60
#   records = [each.value.resource_record_value]
# }

# # Validate ACM Certificate
# resource "aws_acm_certificate_validation" "webs3_main" {
#   certificate_arn = aws_acm_certificate.webs3_main.arn

#   validation_record_fqdns = [
#     for record in aws_route53_record.webs3_certificate_validation : record.fqdn
#   ]

#   timeouts {
#     create = "3h" # Increase timeout to 3 hours or as needed
#   }
# }

# Route 53 Record for Static Website Hosting
resource "aws_route53_record" "webs3_static_website" {
  zone_id = aws_route53_zone.webs3_main.id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_s3_bucket.webs3_static_website.bucket_regional_domain_name
    zone_id                = aws_s3_bucket.webs3_static_website.hosted_zone_id
    evaluate_target_health = true
  }
}

# Outputs section
output "website_url" {
  value = "http://${aws_s3_bucket.webs3_static_website.bucket}.s3-website-${var.region}.amazonaws.com"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.webs3_static_website.bucket
}

output "s3_bucket_website_url" {
  value = aws_s3_bucket.webs3_static_website.website_endpoint
}

output "route53_zone_id" {
  value = aws_route53_zone.webs3_main.id
}

output "route53_record_name" {
  value = aws_route53_record.webs3_static_website.name
}

# output "certificate_arn" {
#   value = aws_acm_certificate.webs3_main.arn
# }

provider "aws" {
  region = var.region
}

variable "domain_name" {
  default = "techconsultio.com"  # Your domain name
}

variable "region" {
  default = "us-west-2"  # AWS region
}

variable "local_files_path" {
  default = "C:/Users/oloos/OneDrive/Desktop/GitCloneWeb"  # Local path for cloning GitHub repository
}

variable "github_repo_url" {
  description = "URL of the GitHub repository to clone files from"
  type        = string
  default     = "https://github.com/StephenLegacy/WebSiteProjectDummy"  # GitHub repo URL
}

resource "aws_s3_bucket" "webs3_static_website" {
  bucket = "webs3-${var.domain_name}-website"
  tags = {
    Name = "webs3-static-website"
  }
}

resource "aws_s3_bucket_public_access_block" "webs3_static_website" {
  bucket = aws_s3_bucket.webs3_static_website.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "webs3_static_website" {
  bucket = aws_s3_bucket.webs3_static_website.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "webs3_static_website_policy" {
  bucket = aws_s3_bucket.webs3_static_website.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.webs3_static_website.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket.webs3_static_website]
}

resource "null_resource" "download_files" {
  provisioner "local-exec" {
    command = <<EOT
      # Ensure the local directory exists
      mkdir -p ${var.local_files_path}
      git clone ${var.github_repo_url} ${var.local_files_path}
    EOT
  }
}

resource "aws_s3_object" "webs3_files" {
  for_each = fileset(var.local_files_path, "*")

  bucket = aws_s3_bucket.webs3_static_website.id
  key    = each.value
  source = "${var.local_files_path}/${each.value}"
  acl    = "public-read"

  depends_on = [null_resource.download_files]
}

output "website_url" {
  value = "http://${aws_s3_bucket.webs3_static_website.bucket}.s3-website-${var.region}.amazonaws.com"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.webs3_static_website.bucket
}

output "s3_bucket_website_url" {
  value = "http://${aws_s3_bucket.webs3_static_website.bucket}.s3-website-${var.region}.amazonaws.com"
}

# Route 53 Configuration (Commented Out)

# resource "aws_route53_zone" "main" {
#   name = var.domain_name
# }

# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.main.id
#   name    = "www.${var.domain_name}"
#   type    = "A"
#   alias {
#     name                   = aws_s3_bucket_website_configuration.webs3_static_website.website_endpoint
#     zone_id                = aws_s3_bucket_website_configuration.webs3_static_website.hosted_zone_id
#     evaluate_target_health = false
#   }
# }

# resource "aws_acm_certificate" "cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   tags = {
#     Name = "cert-${var.domain_name}"
#   }
# }

# resource "aws_route53_record" "cert_validation" {
#   for_each = { for d in aws_acm_certificate.cert.domain_validation_options : d.domain_name => d }
#   zone_id  = aws_route53_zone.main.id
#   name     = each.value.resource_record_name
#   type     = each.value.resource_record_type
#   ttl      = 60
#   records  = [each.value.resource_record_value]
# }

# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

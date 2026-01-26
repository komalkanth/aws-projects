# CloudFront Distribution
# Provides global CDN and entry point for the application
resource "aws_cloudfront_distribution" "main" {
  comment             = "kkoncloud GuardDuty project CloudFront Distribution"
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  # Origin configuration pointing to ALB
  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = aws_lb.main.id

    custom_origin_config {
      http_port              = var.web_port
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id       = aws_lb.main.id
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]

    # Disable caching
    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewer

    compress = true
  }

  # Use default CloudFront certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Geographic restrictions (none)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "kkoncloud GuardDuty project CloudFront Distribution"
  }

  depends_on = [aws_lb.main]
}

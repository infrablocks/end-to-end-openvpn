output "service_dns_name" {
  value = aws_route53_record.public.name
}

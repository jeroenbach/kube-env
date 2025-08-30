output "record_id" {
  description = "The ID of the created DNS record"
  value       = length(cloudflare_dns_record.record) > 0 ? cloudflare_dns_record.record[0].id : null
}

output "record_name" {
  description = "The name of the created DNS record"
  value       = length(cloudflare_dns_record.record) > 0 ? cloudflare_dns_record.record[0].name : null
}

output "record_content" {
  description = "The content of the created DNS record"
  value       = length(cloudflare_dns_record.record) > 0 ? cloudflare_dns_record.record[0].content : null
}

output "record_type" {
  description = "The type of the created DNS record (A or CNAME)"
  value       = length(cloudflare_dns_record.record) > 0 ? cloudflare_dns_record.record[0].type : null
}

output "fqdn" {
  description = "The fully qualified domain name of the record"
  value       = length(cloudflare_dns_record.record) > 0 ? cloudflare_dns_record.record[0].name : null
}
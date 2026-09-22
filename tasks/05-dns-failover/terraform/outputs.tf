output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "route53_name_servers" {
  value = aws_route53_zone.main.name_servers
}

output "route53_record_name" {
  value = aws_route53_record.primary.name
}

output "traffic_manager_fqdn" {
  value = azurerm_traffic_manager_profile.main.fqdn
}

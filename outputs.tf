output "iam_role_arn" {
  description = "IAM Role ARN of Netbox instance"
  value       = aws_iam_role.this.arn
}

output "db_instance_connection_info" {
  description = "DB Instance Connect Info (object)"
  value       = module.netboxdb.instance_connection_info
}

output "db_instance_id" {
  description = "DB Instance ID"
  value       = module.netboxdb.instance_id
}

output "db_password_secretsmanager_arn" {
  description = "Secret ARN for DB password"
  value       = module.netboxdb.password_secretsmanager_arn
}

output "db_password_secretsmanager_version" {
  description = "Secret Version for DB password"
  value       = module.netboxdb.password_secretsmanager_version
}

output "db_username" {
  description = "Master username"
  value       = module.netboxdb.username
}

output "elb_security_group_id" {
  description = "ARN of the ELB for Netbox access"
  value       = aws_security_group.elb.id
}

output "lb_arn" {
  description = "ARN of the ELB for Netbox access"
  value       = aws_lb.this.arn
}

output "lb_listener_arn" {
  description = "ARN of the ELB Listener for Netbox access"
  value       = aws_lb_listener.this.arn
}

output "lb_target_group_arn" {
  description = "ARN of the ELB Target Group for Netbox access"
  value       = aws_lb_target_group.this.arn
}

output "lb_dns_name" {
  description = "DNS Name of the ELB for Netbox access"
  value       = aws_lb.this.dns_name
}

output "lb_zone_id" {
  description = "Route53 Zone ID of the ELB for Netbox access"
  value       = aws_lb.this.zone_id
}

output "url" {
  description = "Netbox Server URL"
  value       = local.netbox_url
}

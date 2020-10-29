data "aws_region" "current" {
}

data "template_cloudinit_config" "this" {

  part {
    content_type = "text/x-shellscript"
    content      = local.configure_script
  }

  part {
    content_type = "text/x-shellscript"
    content      = var.asg_additional_user_data
  }
}

data "aws_route53_zone" "zone" {
  count   = var.zone_id == null ? 0 : 1
  zone_id = var.zone_id
}

locals {
  netbox_url             = "${var.dns_prefix}.${local.domain_name}"
  db_name                = replace(local.short_name, "-", "")
  db_password_secret_arn = coalesce(var.db_netbox_password_secret_arn, module.netbox_db_password.secret_arn)
  db_vpc_id              = coalesce(var.db_vpc_id, var.vpc_id)
  domain_name            = try(trimsuffix(data.aws_route53_zone.zone[0].name, "."), var.domain_name)
  region                 = data.aws_region.current.name
  short_name             = substr(var.name, 0, 32)

  secret_arns = [
    module.netbox_secret.secret_arn,
    local.db_password_secret_arn
  ]

  configure_script = templatefile("${path.module}/templates/configure.sh.tpl",
    {
      base_hostname          = local.netbox_url
      db_hostname            = module.netboxdb.address
      db_username            = var.db_netbox_username
      db_password_secret_arn = local.db_password_secret_arn
      netbox_secret          = module.netbox_secret.secret_arn
      export                 = aws_efs_file_system.this.id
      mount_point            = "/opt/netbox/current/netbox/media"
      region                 = local.region
      site_name              = var.site_name
      start_nginx            = var.asg_start_nginx
    }
  )

  db_allowed_security_groups = concat(
    [aws_security_group.this.id],
    var.db_additional_security_groups
  )
}

module "netbox_db_password" {
  source  = "rhythmictech/secretsmanager-random-secret/aws"
  version = "~> 1.2"

  create_secret = var.db_netbox_password_secret_arn == null
  name_prefix   = "netbox-db-password"
  description   = "Netbox DB Password (username ${var.db_netbox_username})"
  length        = 32
}

module "netbox_secret" {
  source  = "rhythmictech/secretsmanager-random-secret/aws"
  version = "~> 1.2"

  name_prefix = "netbox-secret"
  description = "Netbox Secret Key"
  length      = 60
}

resource "aws_autoscaling_group" "this" {
  name_prefix               = var.name
  desired_capacity          = var.asg_desired_capacity
  force_delete              = false
  health_check_grace_period = 600
  health_check_type         = "ELB"
  launch_configuration      = aws_launch_configuration.this.name
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  target_group_arns         = [aws_lb_target_group.this.id]
  vpc_zone_identifier       = var.asg_subnets
  wait_for_capacity_timeout = "15m"

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = var.name
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      propagate_at_launch = true
      value               = tag.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "this" {
  name_prefix                 = var.name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.this.id
  image_id                    = var.ami_id
  instance_type               = var.asg_instance_type
  key_name                    = var.asg_key_name
  user_data_base64            = data.template_cloudinit_config.this.rendered

  root_block_device {
    encrypted   = true
    volume_size = var.asg_root_volume_size
  }

  security_groups = concat(
    var.asg_additional_security_groups,
    [aws_security_group.this.id]
  )

  lifecycle {
    create_before_destroy = true
  }
}

module "netboxdb" {
  source  = "rhythmictech/rds-postgres/aws"
  version = "~> 3.1.1"

  name                         = local.db_name
  allowed_cidr_blocks          = var.db_allowed_access_cidrs
  allowed_security_groups      = local.db_allowed_security_groups
  backup_retention_period      = var.db_backup_retention_period
  engine_version               = var.db_engine_version
  identifier_prefix            = local.short_name
  instance_class               = var.db_instance_class
  monitoring_interval          = var.db_monitoring_interval
  monitoring_role_arn          = var.db_monitoring_role_arn
  multi_az                     = var.db_multi_az
  parameters                   = var.db_parameters
  pass_version                 = var.db_password_version
  performance_insights_enabled = var.db_performance_insights_enabled
  skip_final_snapshot          = false
  subnet_group_name            = var.db_subnet_group
  storage                      = var.db_storage_size
  tags                         = var.tags
  vpc_id                       = local.db_vpc_id
}

resource "aws_route53_record" "this" {
  count   = var.zone_id != null ? 1 : 0
  name    = var.dns_prefix
  type    = "A"
  zone_id = var.zone_id

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

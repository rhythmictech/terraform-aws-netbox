# terraform-aws-netbox

[![tflint](https://github.com/rhythmictech/terraform-aws-netbox/workflows/tflint/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-netbox/actions?query=workflow%3Atflint+event%3Apush+branch%3Amain)
[![tfsec](https://github.com/rhythmictech/terraform-aws-netbox/workflows/tfsec/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-netbox/actions?query=workflow%3Atfsec+event%3Apush+branch%3Amain)
[![yamllint](https://github.com/rhythmictech/terraform-aws-netbox/workflows/yamllint/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-netbox/actions?query=workflow%3Ayamllint+event%3Apush+branch%3Amain)
[![misspell](https://github.com/rhythmictech/terraform-aws-netbox/workflows/misspell/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-netbox/actions?query=workflow%3Amisspell+event%3Apush+branch%3Amain)
[![pre-commit-check](https://github.com/rhythmictech/terraform-aws-netbox/workflows/pre-commit-check/badge.svg?branch=main&event=push)](https://github.com/rhythmictech/terraform-aws-netbox/actions?query=workflow%3Apre-commit-check+event%3Apush+branch%3Amain)
<a href="https://twitter.com/intent/follow?screen_name=RhythmicTech"><img src="https://img.shields.io/twitter/follow/RhythmicTech?style=social&logo=twitter" alt="follow on Twitter"></a>

Creates an [Netbox](github.com/netbox-community/) instance, optionally bootstrapping the configuration.

## Example
```hcl
data "aws_ami" "netbox" {
  most_recent = true

  owners = [local.account_id]

  filter {
    name   = "name"
    values = ["packer_ubuntu_bionic_netbox_*"]
  }
}

module "netbox_key" {
  source  = "rhythmictech/secure-ssh-key/aws"
  version = "~> 1.0.1"

  name = "netbox-key"
}

resource "aws_key_pair" "netbox_key" {
  key_name_prefix = "netbox"
  public_key      = module.netbox_key.ssh_pubkey
  tags            = local.tags
}

module "netbox" {
  #source = "rhythmictech/netbox/aws"
  source = "../../terraform-aws-netbox"

    ami_id                         = data.aws_ami.netbox.id
  asg_additional_iam_policies    = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  asg_additional_security_groups = [aws_security_group.admin_access.id]
  asg_instance_type              = "t3.large"
  asg_key_name                   = aws_key_pair.netbox_key.id
  asg_subnets                     = ["subnet-123456789"]
  db_instance_class              = "db.t3.medium"
  db_storage_size                = 5
  db_subnet_group                = "database"
  dns_prefix                     = "netbox"
  elb_certificate                = "arn:aws:acm:us-east-1:012345678901:certificate/618601f5-bf87-13d4-a0f6-8a243a54af93"
  elb_subnets                    = ["subnet-123456789", "subnet-012345678"]
  site_name                      = "Netbox"
  vpc_id                         = "vpc-123456789"
  zone_id                        = "zone-123456789"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 2.65 |
| random | >= 1.2 |
| template | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.65 |
| template | >= 2.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ami\_id | AMI to build on (must have `ansible-role-netbox` module installed) | `string` | n/a | yes |
| asg\_subnets | Subnets to associate ASG instances with | `list(string)` | n/a | yes |
| db\_storage\_size | Size of DB (in GB) | `number` | n/a | yes |
| db\_subnet\_group | Database subnet group | `string` | n/a | yes |
| efs\_subnets | Subnets to create EFS mountpoints in | `list(string)` | n/a | yes |
| elb\_certificate | ARN of certificate to associate with ELB | `string` | n/a | yes |
| elb\_subnets | Subnets to associate ELB to | `list(string)` | n/a | yes |
| vpc\_id | VPC to create associated resources in | `string` | n/a | yes |
| asg\_additional\_iam\_policies | Additional IAM policies to attach to the  ASG instance profile | `list(string)` | `[]` | no |
| asg\_additional\_security\_groups | Additional security group IDs to attach to ASG instances | `list(string)` | `[]` | no |
| asg\_additional\_user\_data | Additional User Data to attach to the launch template | `string` | `""` | no |
| asg\_allow\_outbound\_egress | whether or not the default SG should allow outbound egress | `bool` | `true` | no |
| asg\_desired\_capacity | The number of Amazon EC2 instances that should be running in the group. | `number` | `1` | no |
| asg\_instance\_type | Instance type for app | `string` | `"t3a.micro"` | no |
| asg\_key\_name | Optional ssh keypair to associate with instances | `string` | `null` | no |
| asg\_max\_size | Maximum number of instances in the autoscaling group | `number` | `1` | no |
| asg\_min\_size | Minimum number of instances in the autoscaling group | `number` | `1` | no |
| asg\_root\_volume\_size | size of root volume (includes app install but not data dir) | `number` | `20` | no |
| asg\_start\_nginx | should nginx be started (must be started elsewhere in userdata otherwise or the ASG will kill the instance) | `bool` | `true` | no |
| db\_additional\_security\_groups | SGs permitted access to RDS | `list(string)` | `[]` | no |
| db\_allowed\_access\_cidrs | CIDRs permitted access to RDS | `list(string)` | `[]` | no |
| db\_backup\_retention\_period | Number of daily DB backups to retain | `number` | `7` | no |
| db\_engine\_version | engine version to run (netbox at present requires >= 9.6 and < 11) | `string` | `"11"` | no |
| db\_instance\_class | DB Instance Size | `string` | `"db.t3.large"` | no |
| db\_monitoring\_interval | Enhanced monitoring interval (5-60 seconds, 0 to disable) | `number` | `0` | no |
| db\_monitoring\_role\_arn | IAM Role ARN for Database Monitoring permissions (required for performance insights) | `string` | `null` | no |
| db\_multi\_az | If true, DB will be configured in multi-AZ mode | `bool` | `false` | no |
| db\_netbox\_password\_secret\_arn | ARN for SecretsManager secret containing password for Netbox (leave blank to auto-generate) | `string` | `null` | no |
| db\_netbox\_username | Database username for Netbox | `string` | `"netbox"` | no |
| db\_parameters | DB parameters (by default only sets utf8 as required) | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | <pre>[<br>  {<br>    "name": "client_encoding",<br>    "value": "UTF8"<br>  }<br>]</pre> | no |
| db\_password\_version | Increment to force master user password change | `number` | `1` | no |
| db\_performance\_insights\_enabled | Whether or not to enable DB performance insights | `bool` | `false` | no |
| db\_vpc\_id | VPC ID for database (if omitted, the value for `vpc_id` is used instead) | `string` | `null` | no |
| dns\_prefix | The hostname that will be used. This will be combined with the domain in `zone_id` or the value of `domain_name` to form the base url. | `string` | `null` | no |
| domain\_name | domain name, which is only used if `zone_id` is not specified to compute the base url | `string` | `null` | no |
| efs\_additional\_allowed\_security\_groups | Additional security group IDs to attach to the EFS export | `list(string)` | `[]` | no |
| efs\_backup\_retain\_days | Days to retain EFS backups for (only used if `enable_efs_backups=true`) | `number` | `30` | no |
| efs\_backup\_schedule | AWS Backup cron schedule (only used if `enable_efs_backups=true`) | `string` | `"cron(0 5 ? * * *)"` | no |
| efs\_backup\_vault\_name | AWS Backup vault name (only used if `enable_efs_backups=true`) | `string` | `"netbox-efs-vault"` | no |
| elb\_additional\_sg\_tags | Additional tags to apply to the ELB security group. Useful if you use an external process to manage ingress rules. | `map(string)` | `{}` | no |
| elb\_allowed\_cidr\_blocks | List of allowed CIDR blocks. If `[]` is specified, no inbound ingress rules will be created | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| elb\_deregistration\_delay | The deregistration delay for the target group | `number` | `60` | no |
| elb\_healthcheck\_healthy\_threshold | Healthy threshold for ELB healthcheck | `number` | `2` | no |
| elb\_healthcheck\_interval | Interval for ELB healthcheck | `number` | `15` | no |
| elb\_internal | Create as an internal or internet-facing ELB | `bool` | `true` | no |
| elb\_ssl\_policy | SSL Policy to use (see https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html#describe-ssl-policies) | `string` | `"ELBSecurityPolicy-FS-1-2-2019-08"` | no |
| enable\_efs\_backups | Enable EFS backups using AWS Backup (recommended if you aren't going to back up EFS some other way) | `bool` | `false` | no |
| name | Moniker to apply to all resources in the module | `string` | `"netbox"` | no |
| site\_name | Site name | `string` | `"Netbox"` | no |
| tags | User-Defined tags | `map(string)` | `{}` | no |
| zone\_id | Zone ID to make Route53 entry in. If not specified, `domain_name` must be specified so that the base URL can be determined. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| db\_instance\_connection\_info | DB Instance Connect Info (object) |
| db\_instance\_id | DB Instance ID |
| db\_password\_secretsmanager\_arn | Secret ARN for DB password |
| db\_password\_secretsmanager\_version | Secret Version for DB password |
| db\_username | Master username |
| elb\_security\_group\_id | ARN of the ELB for Netbox access |
| iam\_role\_arn | IAM Role ARN of Netbox instance |
| lb\_arn | ARN of the ELB for Netbox access |
| lb\_dns\_name | DNS Name of the ELB for Netbox access |
| lb\_listener\_arn | ARN of the ELB Listener for Netbox access |
| lb\_target\_group\_arn | ARN of the ELB Target Group for Netbox access |
| lb\_zone\_id | Route53 Zone ID of the ELB for Netbox access |
| url | Netbox Server URL |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

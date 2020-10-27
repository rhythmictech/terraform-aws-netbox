# AMI must include the `ansible-role-netbox` role.
data "aws_ami" "netbox" {
  most_recent = true

  owners = ["self"]

  filter {
    name   = "name"
    values = ["netbox_*"]
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
  source = "../.."

  ami_id                         = data.aws_ami.netbox.id
  asg_additional_iam_policies    = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  asg_additional_security_groups = [aws_security_group.admin_access.id]
  asg_instance_type              = "t3.large"
  asg_key_name                   = aws_key_pair.netbox_key.id
  asg_subnets                    = ["subnet-123456789"]
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

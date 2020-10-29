resource "aws_security_group" "this" {
  name_prefix = var.name
  description = "Attached to all Netbox instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { "Name" = var.name }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_inbound_http_from_lb" {
  description              = "Allow HTTP traffic from the load balancer"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = aws_security_group.elb.id
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "allow_outbound" {
  count = var.asg_allow_outbound_egress ? 1 : 0

  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
  description       = "Allow outbound access"
  from_port         = 0
  protocol          = -1
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "egress"
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.netbox_secret.secret_arn]
  }
}

resource "aws_iam_policy" "this" {
  name_prefix = var.name
  policy      = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role" "this" {
  name_prefix        = var.name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_role_policy_attachment" "additional" {
  count      = length(var.asg_additional_iam_policies)
  role       = aws_iam_role.this.name
  policy_arn = var.asg_additional_iam_policies[count.index]
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = var.name
  role        = aws_iam_role.this.name
}

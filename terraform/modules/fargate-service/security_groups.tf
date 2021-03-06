
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "${var.name_prefix}-ecs-tasks-sg"
  vpc_id      = var.vpc_id
  tags        = merge(var.common_tags, { Name = "${var.name_prefix}-ecs-tasks-sg" })
}

resource "aws_security_group" "lb_sg" {
  name                   = "${var.name_prefix}-lb-sg"
  description            = "Control access to LB"
  vpc_id                 = var.vpc_id
  tags                   = merge(var.common_tags, { Name = "${var.name_prefix}-lb-sg" })
  revoke_rules_on_delete = true
}

resource aws_security_group_rule ingress_from_alb {
  description              = "ingress_from_alb"
  from_port                = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  to_port                  = var.container_port
  type                     = "ingress"
  source_security_group_id = aws_security_group.lb_sg.id
}

resource aws_security_group_rule ingress_https_to_vpc_endpoints {
  description              = "ingress_https_to_vpc_endpoints"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = var.interface_vpce_sg_id
  to_port                  = 443
  type                     = "ingress"
  source_security_group_id = aws_security_group.ecs_tasks_sg.id
}

resource aws_security_group_rule egress_to_ecs_tasks {
  description              = "egress_to_ecs_tasks"
  from_port                = var.container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lb_sg.id
  to_port                  = var.container_port
  type                     = "egress"
  source_security_group_id = aws_security_group.ecs_tasks_sg.id
}

resource aws_security_group_rule egress_to_vpce {
  description              = "egress__https_to_vpc_endpoints"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  to_port                  = 443
  type                     = "egress"
  source_security_group_id = var.interface_vpce_sg_id
}

resource aws_security_group_rule egress_to_s3_pl {
  description       = "egress_to_s3_pl"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_tasks_sg.id
  to_port           = 443
  type              = "egress"
  prefix_list_ids   = [var.s3_prefixlist_id]
}

resource aws_security_group_rule egress_to_dynamodb_pl {
  description       = "egress_to_dynamodb_pl"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_tasks_sg.id
  to_port           = 443
  type              = "egress"
  prefix_list_ids   = [var.dynamodb_prefixlist_id]
}

resource "aws_security_group_rule" "internet_proxy_endpoint_from_ecs_task" {
  description              = "Accept requests to Internet Proxy endpoint from Concourse Web nodes"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = var.internet_proxy_vpce_sg_id
  source_security_group_id = aws_security_group.ecs_tasks_sg.id
}

resource "aws_security_group_rule" "ecs_tasks_to_internet_proxy_endpoint" {
  description              = "Allow Concourse Web nodes to reach Internet Proxy endpoint"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = aws_security_group.ecs_tasks_sg.id
  source_security_group_id = var.internet_proxy_vpce_sg_id
}

#
# == Manifest: Project: Security Groups: logs-cdn
#
# Prometheus needs to be accessible on ports:
#   - 9090
#
# === Variables:
# stackname - string
# office_ips - array of CIDR blocks
#
# === Outputs:
# sg_prometheus_id
# sg_prometheus_elb_id

resource "aws_security_group" "sg_prometheus_elb" {
  name        = "${var.stackname}_prometheus_elb"
  vpc_id      = "${data.terraform_remote_state.infra_vpc.vpc_id}"
  description = "Access to prometheus from its ELB"

  tags {
    Name = "${var.stackname}_prometheus_elb"
  }
}

resource "aws_security_group_rule" "prometheus-elb-ingress-https" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  # Which security group is the rule assigned to
  security_group_id = "${aws_security_group.sg_prometheus_ingress}"

  # Which security group can use this rule
  source_security_group_id = "${aws_security_group.sg_prometheus_ingress}"
}

resource "aws_security_group" "sg_prometheus_ingress" {
  name        = "${var.stackname}_prometheus_ingress"
  vpc_id      = "${data.terraform_remote_state.infra_vpc.vpc_id}"
  description = "Access to prometheus"

  tags {
    Name = "${var.stackname}_prometheus_ingress"
  }
}

resource "aws_security_group_rule" "logs-cdn-elb_ingress_fastly_syslog-tls" {
  type              = "ingress"
  to_port           = 6516
  from_port         = 6514
  protocol          = "tcp"
  security_group_id = "${aws_security_group.logs-cdn_elb.id}"
  cidr_blocks       = ["${data.fastly_ip_ranges.fastly.cidr_blocks}"]
}

resource "aws_security_group_rule" "logs-cdn-elb_egress_any_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.logs-cdn_elb.id}"
}

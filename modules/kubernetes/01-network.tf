data "aws_vpc" "targeted_vpc" {
  id      = "${var.vpc_id}"
  default = false
  state   = "available"
}

resource "aws_subnet" "k8s_private" {
  count                   = "${length(var.subnets_private_cidr_block)}"
  vpc_id                  = "${data.aws_vpc.targeted_vpc.id}"
  availability_zone       = "${var.availability_zone[count.index]}"
  cidr_block              = "${var.subnets_private_cidr_block[count.index]}"
  map_public_ip_on_launch = "false"

  tags {
    Name                              = "${var.unique_identifier} ${var.environment} k8s private subnet"
    managed                           = "terraform (k8s module)"
    KubernetesCluster                 = "${var.kubernetes_cluster}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "k8s_public" {
  count                   = "${length(var.subnets_public_cidr_block)}"
  vpc_id                  = "${data.aws_vpc.targeted_vpc.id}"
  availability_zone       = "${var.availability_zone[count.index]}"
  cidr_block              = "${var.subnets_public_cidr_block[count.index]}"
  map_public_ip_on_launch = "true"

  tags {
    Name                     = "${var.unique_identifier} ${var.environment} k8s public subnet"
    managed                  = "terraform (k8s module)"
    KubernetesCluster        = "${var.kubernetes_cluster}"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_route_table" "k8s_private_route_table" {
  vpc_id = "${data.aws_vpc.targeted_vpc.id}"

  tags {
    Name              = "${var.unique_identifier} ${var.environment} k8s private route table"
    managed           = "terraform"
    KubernetesCluster = "${var.kubernetes_cluster}"
  }
}

resource "aws_route_table" "k8s_public_route_table" {
  vpc_id = "${data.aws_vpc.targeted_vpc.id}"

  tags {
    Name              = "${var.unique_identifier} ${var.environment} k8s public route table"
    managed           = "terraform"
    KubernetesCluster = "${var.kubernetes_cluster}"
  }
}

resource "aws_route_table_association" "k8s_private_route_table_assoc" {
  count          = "${length(var.subnets_private_cidr_block)}"
  subnet_id      = "${element(aws_subnet.k8s_private.*.id, count.index)}"
  route_table_id = "${aws_route_table.k8s_private_route_table.id}"
}

resource "aws_route_table_association" "k8s_public_route_table_assoc" {
  count          = "${length(var.subnets_public_cidr_block)}"
  subnet_id      = "${element(aws_subnet.k8s_public.*.id, count.index)}"
  route_table_id = "${aws_route_table.k8s_public_route_table.id}"
}

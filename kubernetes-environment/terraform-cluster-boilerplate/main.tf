provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


#--------- IAM -----------

# K8s master role policy
data "aws_iam_policy_document" "master-iam-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    resources = ["*"]
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "iam:CreateServiceLinkedRole",
      "kms:DescribeKey",
    ]
  }
}

resource "aws_iam_role_policy" "vn-k8s-backdoor-master-iam-policy" {
  name = "vn-k8s-backdoor-master-iam-policy"
  role = aws_iam_role.vn-k8s-backdoor-iam-master-role.id

  policy = data.aws_iam_policy_document.master-iam-policy-doc.json
}

# K8s worker role policy
data "aws_iam_policy_document" "worker-iam-policy-doc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    resources = ["*"]
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage",
    ]
  }
}

resource "aws_iam_role_policy" "vn-k8s-backdoor-worker-iam-policy" {
  name = "vn-k8s-backdoor-worker-iam-policy"
  role = aws_iam_role.vn-k8s-backdoor-iam-worker-role.id

  policy = data.aws_iam_policy_document.worker-iam-policy-doc.json
}


# K8s master common role
resource "aws_iam_role" "vn-k8s-backdoor-iam-master-role" {
  name               = "vn-k8s-backdoor-iam-master-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

# K8s worker role
resource "aws_iam_role" "vn-k8s-backdoor-iam-worker-role" {
  name               = "vn-k8s-backdoor-iam-worker-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

resource "aws_iam_instance_profile" "vn-k8s-backdoor-iam-master-profile" {
  name = "vn-k8s-backdoor-iam-master-profile"
  role = aws_iam_role.vn-k8s-backdoor-iam-master-role.name
}

resource "aws_iam_instance_profile" "vn-k8s-backdoor-iam-worker-profile" {
  name = "vn-k8s-backdoor-iam-worker-profile"
  role = aws_iam_role.vn-k8s-backdoor-iam-worker-role.name
}

#--------- VPC -----------

resource "aws_vpc" "vn-k8s-backdoor-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

resource "aws_internet_gateway" "vn-k8s-backdoor-ig" {
  vpc_id = aws_vpc.vn-k8s-backdoor-vpc.id

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

resource "aws_route_table" "vn-k8s-backdoor-rt" {
  vpc_id = aws_vpc.vn-k8s-backdoor-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vn-k8s-backdoor-ig.id
  }

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

resource "aws_subnet" "vn-k8s-backdoor-subnet" {
  vpc_id                  = aws_vpc.vn-k8s-backdoor-vpc.id
  cidr_block              = var.vpc_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]


  tags = {
    Owner = var.k8s_cluster_owner
  }
}

resource "aws_route_table_association" "vn-k8s-backdoor-rta" {
  subnet_id      = aws_subnet.vn-k8s-backdoor-subnet.id
  route_table_id = aws_route_table.vn-k8s-backdoor-rt.id
}

# Security Groups
resource "aws_security_group" "vn-k8s-backdoor-sg-ssh" {
  vpc_id      = aws_vpc.vn-k8s-backdoor-vpc.id
  name        = "vn-k8s-backdoor-sg-ssh"
  description = "SG for ssh access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

resource "aws_security_group" "vn-k8s-backdoor-sg-common" {
  vpc_id      = aws_vpc.vn-k8s-backdoor-vpc.id
  name        = "vn-k8s-backdoor-sg-common"
  description = "SG for k8s cluster nodes, allow all k8s used ports for master/workers"

  ingress {
    # port means icmp types for icmp protocol
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "pingable"
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k8s-apiserver"
  }
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k8s-etcd"
  }
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k8s kubelet health"
  }
  ingress {
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k8s kubelet api"
  }
  ingress {
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k8s controller manager"
  }
  ingress {
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "k8s scheduler"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Owner = var.k8s_cluster_owner
  }
}


#--------- EC2 -----------

resource "aws_key_pair" "vn-k8s-backdoor-key-pair" {
  key_name   = var.ssh_key_name
  public_key = file(var.ssh_public_key_path)

  tags = {
    Owner = var.k8s_cluster_owner
  }
}

# Master node
resource "aws_instance" "vn-k8s-backdoor-master" {
  instance_type = var.k8s_master_instance_type
  ami           = var.k8s_master_ami

  key_name               = aws_key_pair.vn-k8s-backdoor-key-pair.id
  vpc_security_group_ids = [aws_security_group.vn-k8s-backdoor-sg-ssh.id, aws_security_group.vn-k8s-backdoor-sg-common.id]
  iam_instance_profile   = aws_iam_instance_profile.vn-k8s-backdoor-iam-master-profile.id
  subnet_id              = aws_subnet.vn-k8s-backdoor-subnet.id

  tags = {
    Owner = var.k8s_cluster_owner
    Name  = "vn-k8s-backdoor-master-0"
  }
}

# Worker nodes
resource "aws_instance" "vn-k8s-backdoor-worker" {
  instance_type = var.k8s_worker_instance_type
  ami           = var.k8s_worker_ami
  count         = 2

  key_name               = aws_key_pair.vn-k8s-backdoor-key-pair.id
  vpc_security_group_ids = [aws_security_group.vn-k8s-backdoor-sg-ssh.id, aws_security_group.vn-k8s-backdoor-sg-common.id]
  iam_instance_profile   = aws_iam_instance_profile.vn-k8s-backdoor-iam-worker-profile.id
  subnet_id              = aws_subnet.vn-k8s-backdoor-subnet.id

  tags = {
    Owner = var.k8s_cluster_owner
    Name  = "vn-k8s-backdoor-worker-${count.index}"
  }
}

output "instance_ips" {
  value = [aws_instance.vn-k8s-backdoor-worker[*].public_ip, aws_instance.vn-k8s-backdoor-master.public_ip]
}

resource "local_file" "ansible-inventory" {
  filename = "ansible-hosts"
  content  = <<EOT
[k8s-boilerplate]
${aws_instance.vn-k8s-backdoor-master.public_ip}
%{for ip in aws_instance.vn-k8s-backdoor-worker[*].public_ip~}
${ip}
%{endfor~}
EOT
}

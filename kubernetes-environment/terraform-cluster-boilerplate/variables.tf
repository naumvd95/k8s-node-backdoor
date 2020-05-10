variable "aws_profile" {}
variable "aws_region" {}
data "aws_availability_zones" "available" {}

variable "vpc_cidr" {}
variable "vpc_subnet_cidr" {}

variable "k8s_cluster_owner" {}
variable "k8s_cluster_name" {}
variable "ssh_public_key_path" {}
variable "ssh_key_name" {}

variable "k8s_master_instance_type" {}
variable "k8s_master_ami" {}
variable "k8s_worker_instance_type" {}
variable "k8s_worker_ami" {}
variable "k8s_ip_output_path" {}

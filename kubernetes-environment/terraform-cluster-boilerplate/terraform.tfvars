aws_region = "us-east-2"

vpc_cidr        = "11.0.0.0/16"
vpc_subnet_cidr = "11.0.0.0/24"

k8s_cluster_owner = "vnaumov"
# TODO parametrize cluster name though ansible parameters
k8s_cluster_name = "vn-cluster"
ssh_key_name     = "vn-k8s-backdoor-key-pair"

k8s_master_instance_type = "c5d.large"
k8s_master_ami           = "ami-033a0960d9d83ead0"
k8s_worker_instance_type = "c5d.large"
k8s_worker_ami           = "ami-033a0960d9d83ead0"
k8s_ip_output_path       = "cluster-ip.log"

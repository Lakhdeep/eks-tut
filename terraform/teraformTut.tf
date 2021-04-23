provider "aws" {
  region = "ap-southeast-1"
}

# resource "aws_instance" "lakhdeep_machine" {
# 	ami = "ami_063e2a44db52cc23d"
# 	instance_type = "t2.micro"
# 	tags = {
# 		Name: "lakhdeep_ubuntu"
# 	}
# }

resource "aws_vpc" "lakhdeep_tf_vpc" {
  cidr_block       = "192.1.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "lakhdeep_tf_vpc"
  }
}

resource "aws_subnet" "lakhdeep_tf_subnet_1" {
  vpc_id            = aws_vpc.lakhdeep_tf_vpc.id
  cidr_block        = "192.1.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "lakhdeep_tf_subnet_1"
  }
}

resource "aws_subnet" "lakhdeep_tf_subnet_2" {
  vpc_id     = aws_vpc.lakhdeep_tf_vpc.id
  cidr_block = "192.1.2.0/24"

  tags = {
    Name = "lakhdeep_tf_subnet_2"
  }
}

resource "aws_subnet" "lakhdeep_tf_subnet_3" {
  vpc_id            = aws_vpc.lakhdeep_tf_vpc.id
  cidr_block        = "192.1.3.0/24"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "lakhdeep_tf_subnet_3"
  }
}

resource "aws_subnet" "lakhdeep_tf_subnet_4" {
  vpc_id     = aws_vpc.lakhdeep_tf_vpc.id
  cidr_block = "192.1.4.0/24"

  tags = {
    Name = "lakhdeep_tf_subnet_4"
  }
}

resource "aws_internet_gateway" "lakhdeep_tf_igw" {
  vpc_id = aws_vpc.lakhdeep_tf_vpc.id

  tags = {
    Name = "lakhdeep_tf_igw"
  }
}

resource "aws_route_table" "lakhdeep_tf_rt_1" {
  vpc_id = aws_vpc.lakhdeep_tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lakhdeep_tf_igw.id
  }

  tags = {
    Name = "lakhdeep_tf_rt_1"
  }
}

resource "aws_route_table" "lakhdeep_tf_rt_3" {
  vpc_id = aws_vpc.lakhdeep_tf_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lakhdeep_tf_nat.id
  }

  tags = {
    Name = "lakhdeep_tf_rt_3"
  }
}

resource "aws_route_table_association" "lakhdeep_tf_rta_1" {
  subnet_id      = aws_subnet.lakhdeep_tf_subnet_1.id
  route_table_id = aws_route_table.lakhdeep_tf_rt_1.id
}

resource "aws_route_table_association" "lakhdeep_tf_rta_3" {
  subnet_id      = aws_subnet.lakhdeep_tf_subnet_3.id
  route_table_id = aws_route_table.lakhdeep_tf_rt_3.id
}

resource "aws_nat_gateway" "lakhdeep_tf_nat" {
  allocation_id = aws_eip.lakhdeep_tf_eip.id
  subnet_id     = aws_subnet.lakhdeep_tf_subnet_1.id

  tags = {
    Name = "lakhdeep_tf_nat"
  }
}

resource "aws_eip" "lakhdeep_tf_eip" {
  vpc = true

  tags = {
    Name = "lakhdeep_tf_eip"
  }
}



data "aws_eks_cluster" "cluster" {
  name = module.lakhdeep_tf_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.lakhdeep_tf_cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "lakhdeep_tf_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "lakhdeep_tf_cluster"
  cluster_version = "1.19"
  subnets         = [aws_subnet.lakhdeep_tf_subnet_1.id, aws_subnet.lakhdeep_tf_subnet_3.id]
  vpc_id          = aws_vpc.lakhdeep_tf_vpc.id

  worker_groups = [
    {
      instance_type = "t3.small"
      asg_max_size  = 2
      subnets       = [aws_subnet.lakhdeep_tf_subnet_3.id]
    }
  ]

  workers_group_defaults = {
    root_volume_type = "gp2"
  }
}

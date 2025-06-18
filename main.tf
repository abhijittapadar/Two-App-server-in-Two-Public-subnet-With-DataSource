terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}



module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"


  name = "public-Vpc"
  cidr = "10.0.0.0/16"
  azs = ["us-east-1a", "us-east-1b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "Publick-VPC"
  }
}

module "sg-public" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name = "public-SG"
  vpc_id = module.vpc.vpc_id
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules  = ["http-80-tcp"]
  egress_rules = ["all-all"]
  
}


data "aws_ami" "amzlinux2" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-gp2" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
}

module "ec2-instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.8.0"
  name = "My-Web-App"
  ami = data.aws_ami.amzlinux2.id
  associate_public_ip_address = true
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  subnet_id = module.vpc.public_subnets[0]
  user_data = file("${path.module}/app.sh")
  vpc_security_group_ids = [module.sg-public.security_group_id]
}

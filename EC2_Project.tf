variable "my_tags" {
  type    = map(string)
  default = { "name" = "EC2_Project", "Owner" = "Arsen" }
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.access_key
  secret_key = var.secret_key 
}

resource "aws_vpc" "aws_network" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = var.my_tags
}

resource "aws_subnet" "Subnet_1" {
  vpc_id = aws_vpc.aws_network.id
  #vpc_id     = "vpc-0118604cbb683e868"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = var.my_tags
}

resource "aws_security_group" "SecGroup1" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.aws_network.id

  ingress {
    description      = "Port_443_VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.aws_network.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.aws_network.ipv6_cidr_block]
  }


  ingress {
    description      = "Port_80_VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.aws_network.cidr_block]
    ipv6_cidr_blocks = [aws_vpc.aws_network.ipv6_cidr_block]
  }

  ingress {
    description      = "SSH_VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.my_tags
}

resource "aws_internet_gateway" "Gateway1" {
  vpc_id = aws_vpc.aws_network.id

  tags = var.my_tags
}

resource "aws_route_table" "RT1" {
  vpc_id = aws_vpc.aws_network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Gateway1.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.Gateway1.id
  }

  tags = var.my_tags
}

resource "aws_instance" "EC2-1" {
  ami           = "ami-03503cee055fc9c47"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.Subnet_1.id
  key_name      = "Terraform-key"
  tags          = var.my_tags
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Subnet_1.id
  route_table_id = aws_route_table.RT1.id
}
resource "aws_key_pair" "Terraform" {
  key_name   = "Terraform-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvfg7FQL7kLm9pYTBrDIXG7ECGjBjyNVroJnryyCahVH2tn1gSeNFlnAv45Y8xmvi9q0FpKAXnZNRBtEkesVSbTJ6zAsKSDM9IgGH7JV+htKCd6ZISCVTQD/hmijUbdMjfK8uVRWq+4HrCYeFDdFSz6T9a6Aj3SptjmSMQcJQ9aekW2ZgxegiggCFJATZ0JkVwDuG5FQSHftwZlfCNszxuHLKp/gXLLr+VC31YvQB9hcZTUjEgJy4vEhB3sXHjN4t/JEYbO0N+nNfbjFS+07GY+4l+7Cm6zVjp04g9zSJzbtpSj87BnMJDwgd5mp2cj2HftLo9oWuxMujImxjeuoDt terraform_EC2"
}
output "instance_ip_addr" {
  value = aws_instance.EC2-1.public_ip
}

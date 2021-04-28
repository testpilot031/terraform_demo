# ====================
#
# VPC
#
# ====================
resource "aws_vpc" "example" {
  cidr_block           = "199.0.0.0/16"
  enable_dns_support   = true # DNS解決を有効化
  enable_dns_hostnames = true # DNSホスト名を有効化

  tags = {
    Name = "example"
  }
}

# ====================
#
# Subnet
#
# ====================
resource "aws_subnet" "public_0" {
  cidr_block        = "199.0.10.0/24"
  availability_zone = var.aws_az_1
  vpc_id            = aws_vpc.example.id

  # trueにするとインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
  map_public_ip_on_launch = false

  tags = {
    Name = "example"
  }
}
resource "aws_subnet" "public_1" {
  cidr_block        = "199.0.20.0/24"
  availability_zone = var.aws_az_2
  vpc_id            = aws_vpc.example.id

  # trueにするとインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
  map_public_ip_on_launch = false

  tags = {
    Name = "example"
  }
}
resource "aws_subnet" "private_0" {
  cidr_block        = "199.0.30.0/24"
  availability_zone = var.aws_az_1
  vpc_id            = aws_vpc.example.id

  # trueにするとインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
  map_public_ip_on_launch = false

  tags = {
    Name = "example"
  }
}
resource "aws_subnet" "private_1" {
  cidr_block        = "199.0.40.0/24"
  availability_zone = var.aws_az_2
  vpc_id            = aws_vpc.example.id

  # trueにするとインスタンスにパブリックIPアドレスを自動的に割り当ててくれる
  map_public_ip_on_launch = false

  tags = {
    Name = "example"
  }
}
# ====================
#
# Internet Gateway
#
# ====================
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example"
  }
}

# ====================
#
# Route Table
#
# ====================
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example"
  }
}

resource "aws_route" "example" {
  gateway_id             = aws_internet_gateway.example.id
  route_table_id         = aws_route_table.example.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "example_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.example.id
}

# ====================
#
# Security Group
#
# ====================
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id
  name   = "example"

  tags = {
    Name = "example"
  }
}

# インバウンドルール(ssh接続用)
resource "aws_security_group_rule" "in_ssh" {
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = [aws_vpc.example.cidr_block]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}
# インバウンドルール(db用)
resource "aws_security_group_rule" "in_db" {
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = [aws_vpc.example.cidr_block]
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
}

# インバウンドルール(pingコマンド用)
resource "aws_security_group_rule" "in_icmp" {
  security_group_id = aws_security_group.example.id
  type              = "ingress"
  cidr_blocks       = [aws_vpc.example.cidr_block]
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
}

# アウトバウンドルール(全開放)
resource "aws_security_group_rule" "out_all" {
  security_group_id = aws_security_group.example.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}
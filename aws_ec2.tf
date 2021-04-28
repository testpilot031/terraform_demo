# ====================
#
# AMI
#
# ====================
# 最新版のAmazonLinux2のAMI情報
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ====================
#
# EC2 Instance
#
# ====================
resource "aws_instance" "example_1" {
  ami                    = data.aws_ami.example.image_id
  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = aws_subnet.private_0.id
  key_name               = aws_key_pair.example.id
  instance_type          = "t2.micro"

  tags = {
    Name = "example_1"
  }
}
resource "aws_instance" "example_2" {
  ami                    = data.aws_ami.example.image_id
  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = aws_subnet.private_1.id
  key_name               = aws_key_pair.example.id
  instance_type          = "t2.micro"

  tags = {
    Name = "example_2"
  }
}
# ====================
#
# Elastic IP
#
# ====================
#resource "aws_eip" "example" {
#  instance = aws_instance.example.id
#  vpc      = true
#}

# RDS
resource "aws_db_subnet_group" "private_db" {
  name       = "private-db"
  subnet_ids = ["${aws_subnet.private_0.id}", "${aws_subnet.private_1.id}"]
  tags = {
    Name = "example"
  }
}

resource "aws_db_instance" "test_db" {
  identifier             = "testdb"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "11.5"
  instance_class         = "db.t3.micro"
  name                   = "test_db"
  username               = "test12345"
  password               = "test123456"
  vpc_security_group_ids = ["${aws_security_group.example.id}"]
  db_subnet_group_name   = aws_db_subnet_group.private_db.name
  skip_final_snapshot    = true
  tags = {
    Name = "example"
  }
}

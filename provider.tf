# AWS基本設定
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "ap-northeast-1"
}


resource "aws_vpc" "rds" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "rds"
  }
}

resource "aws_internet_gateway" "rds" {
  vpc_id = aws_vpc.rds.id

  tags = {
    Name = "rds"
  }
}

resource "aws_default_route_table" "public" {
  tags = {
    Name = "public-rt"
  }
  default_route_table_id = aws_vpc.rds.default_route_table_id
}

resource "aws_route" "public" {
  route_table_id         = aws_default_route_table.public.id
  gateway_id             = aws_internet_gateway.rds.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_subnet" "public-subnet-1" {
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "ap-northeast-1a"
  vpc_id                  = aws_vpc.rds.id
  map_public_ip_on_launch = true
  tags = {
    Name = "rds-public"
  }
}

resource "aws_subnet" "public-subnet-2" {
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "ap-northeast-1c"
  vpc_id                  = aws_vpc.rds.id
  map_public_ip_on_launch = true
  tags = {
    Name = "rds-public"
  }
}

resource "aws_security_group" "rds-sg" {
  vpc_id = aws_vpc.rds.id
  name   = "rds-sg"
  ingress {
    from_port   = 3306
    protocol    = "TCP"
    to_port     = 3306
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "public-db" {
  name        = "public-db"
  subnet_ids  = [
    aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
  tags = {
    Name = "public-db"
  }
}

resource "aws_db_instance" "rds" {
  identifier = "terraform-rds"
  allocated_storage = 10
  instance_class = "db.t3.micro"
  engine = "mysql"
  engine_version = "8.0.20"
  storage_type = "gp2"
  storage_encrypted = true
  multi_az = true
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  db_subnet_group_name = aws_db_subnet_group.public-db.name
  username = var.aws_rds_username
  password = var.aws_rds_password
  publicly_accessible = true
}

output "rds_host" {
  value = aws_db_instance.rds.endpoint
}
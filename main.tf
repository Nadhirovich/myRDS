terraform {
  required_version = ">= 1.3.7, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.7"
    }
  }

}

provider "aws" {
  region = "eu-central-1"
  
}


//Create VPC and subnets

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
}

// create security groupe

resource "aws_security_group" "rds_sg" {
  name_prefix = "rds-"

  vpc_id = aws_vpc.my_vpc.id

  # Add any additional ingress/egress rules as needed
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


//create RDS Subnet groups

resource "aws_db_subnet_group" "my_db_subnet_group" {

  name = "my-db-subnet-group"

  subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]



  tags = {

    Name = "My DB Subnet Group"

  }

}

// Create RDS database 
resource "aws_db_instance" "default" {

  allocated_storage = 10

  storage_type = "gp2"

  engine = "mysql"

  engine_version = "5.7"

  instance_class = "db.t2.micro"

  identifier = "mydb"

  username = "dbuser"

  password = "dbpassword"



  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name



  skip_final_snapshot = true

}


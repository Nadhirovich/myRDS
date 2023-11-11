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

  allocated_storage = 20

  storage_type = "gp2"

  engine = "mysql"

  engine_version = "5.7"

  instance_class = "db.t3.medium"

  identifier = "mydb"

  username = "dbuser"

  password = "dbpassword"



  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_subnet_group_name = aws_db_subnet_group.my_db_subnet_group.name


  backup_retention_period = 7 # Number of days to retain automated backups

  backup_window = "03:00-04:00" # Preferred UTC backup window (hh24:mi-hh24:mi format)

  maintenance_window = "mon:04:00-mon:04:30" # Preferred UTC maintenance window

  
   # Enable automated backups

  skip_final_snapshot = false

  final_snapshot_identifier = "db-snap"

  
  
  # Enable enhanced monitoring

  monitoring_interval = 60 # Interval in seconds (minimum 60 seconds)

  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn



  # Enable performance insights

  performance_insights_enabled = true

  

  # Enable storage encryption

  storage_encrypted = true

  # Specify the KMS key ID for encryption (replace with your own KMS key ARN)

  kms_key_id = aws_kms_key.my_kms_key.arn


}

// create IAM role with appropriate access to CloudWatch

resource "aws_iam_role" "rds_monitoring_role" {

  name = "rds-monitoring-role"



  assume_role_policy = jsonencode({

  Version = "2012-10-17",

  Statement = [

      {

        Action = "sts:AssumeRole",

        Effect = "Allow",

        Principal = {

        Service = "monitoring.rds.amazonaws.com"

      }

    }

  ]

})

}

// create the policy and attach it to the IAM role

resource "aws_iam_policy_attachment" "rds_monitoring_attachment" {

  name = "rds-monitoring-attachment"

  roles = [aws_iam_role.rds_monitoring_role.name]

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"

}

//To enable encryption for our RDS database

// create the KMS key

resource "aws_kms_key" "my_kms_key" {

  description = "My KMS Key for RDS Encryption"

  deletion_window_in_days = 30



  tags = {

    Name = "MyKMSKey"

  }

}


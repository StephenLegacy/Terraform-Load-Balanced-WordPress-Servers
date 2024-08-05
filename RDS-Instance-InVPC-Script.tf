# Define the AWS provider and region


# Define variables for configuration
variable "use_existing_vpc" {
  description = "Flag to use an existing VPC. Set to true to use existing, false to create a new one."
  default     = true
}

variable "vpc_id" {
  description = "ID of the existing VPC to use if use_existing_vpc is true."
  type        = string
  default     = ""
}

variable "db_name" {
  description = "The name of the database instance."
  default     = "mydb"
}

variable "db_username" {
  description = "The username for the database."
  default     = "admin"
}

variable "db_password" {
  description = "The password for the database."
  default     = "password"
  sensitive   = true
}

variable "db_instance_class" {
  description = "The instance class of the database."
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage size for the database (in GB)."
  default     = 20
}

variable "engine" {
  description = "The database engine to use."
  default     = "mysql"
}

variable "engine_version" {
  description = "The version of the database engine."
  default     = "8.0"
}

variable "publicly_accessible" {
  description = "Whether the database instance should be publicly accessible."
  default     = false
}

# Fetch the existing VPC if use_existing_vpc is true
data "aws_vpc" "rds_existing" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

# Create a new VPC if use_existing_vpc is false
resource "aws_vpc" "rds_vpc" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "RDSProjectVPC"
  }
}

# Fetch subnets of the existing VPC if use_existing_vpc is true
data "aws_subnets" "rds_existing" {
  count = var.use_existing_vpc ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.rds_existing[0].id]
  }
}

# Create new subnets if use_existing_vpc is false
resource "aws_subnet" "rds_subnet_a" {
  count                     = var.use_existing_vpc ? 0 : 1
  vpc_id                    = aws_vpc.rds_vpc[0].id
  cidr_block                = "10.0.1.0/24"
  availability_zone         = "us-west-2a"
  map_public_ip_on_launch   = true

  tags = {
    Name = "RDSProjectSubnetA"
  }
}

resource "aws_subnet" "rds_subnet_b" {
  count                     = var.use_existing_vpc ? 0 : 1
  vpc_id                    = aws_vpc.rds_vpc[0].id
  cidr_block                = "10.0.5.0/24"
  availability_zone         = "us-west-2b"
  map_public_ip_on_launch   = true

  tags = {
    Name = "RDSProjectSubnetB"
  }
}

# Local values to select the appropriate VPC ID and subnet IDs based on use_existing_vpc flag
locals {
  selected_vpc_id      = var.use_existing_vpc ? data.aws_vpc.rds_existing[0].id : aws_vpc.rds_vpc[0].id
  selected_subnet_ids  = var.use_existing_vpc ? data.aws_subnets.rds_existing[0].ids : [aws_subnet.rds_subnet_a[0].id, aws_subnet.rds_subnet_b[0].id]
}

# Create the DB subnet group
resource "aws_db_subnet_group" "rds_main" {
  name       = "mydb-subnet-group"
  subnet_ids = local.selected_subnet_ids

  tags = {
    Name = "mydb-subnet-group"
  }
}

# Create the RDS instance
resource "aws_db_instance" "rds_main" {
  identifier              = var.db_name
  allocated_storage       = var.allocated_storage
  storage_type            = "gp2"
  engine                  = var.engine
  engine_version          = var.engine_version
  instance_class          = var.db_instance_class
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds_main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = var.publicly_accessible

  tags = {
    Name = "mydb-instance"
  }
}

# Security group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow access to RDS instance"
  vpc_id      = local.selected_vpc_id

  # Allow ingress traffic on port 3306 (MySQL)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust CIDR blocks as necessary
  }

  # Allow all egress traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}

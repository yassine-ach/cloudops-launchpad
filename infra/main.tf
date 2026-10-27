terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket       = "cloudops-launchpad-tfstate-yassine-ach"
    key          = "cloudops-launchpad/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "${var.project_name}-public-a"
  }
}
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "${var.project_name}-private-a"
  }
}
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "${var.project_name}-public-b"
  }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "${var.project_name}-private-b"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_ecr_repository" "ecr_rep" {
  name         = "${var.project_name}-ecr"
  force_delete = true
  tags = {
    Name = "${var.project_name}-ecr"
  }
}

resource "aws_cloudwatch_log_group" "c_watch" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
  tags = {
    Name = "${var.project_name}-cloud-watch"
  }
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs-execution"
  tags = {
    Name = "${var.project_name}-ecs-execution"
  }

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_security_group" "alb_sec" {
  name        = "${var.project_name}-alb"
  description = "Security Group for the Load Balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-alb-sec"
  }
}

resource "aws_security_group" "tasks_sec" {
  name        = "${var.project_name}-tasks-sec"
  description = "Security group for the ECS tasks"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-tasks-sec"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_from_internet" {
  security_group_id = aws_security_group.alb_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "task_from_alb" {
  security_group_id            = aws_security_group.tasks_sec.id
  referenced_security_group_id = aws_security_group.alb_sec.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}

resource "aws_vpc_security_group_egress_rule" "task_out" {
  security_group_id = aws_security_group.tasks_sec.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb_sec.id
  referenced_security_group_id = aws_security_group.tasks_sec.id
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}
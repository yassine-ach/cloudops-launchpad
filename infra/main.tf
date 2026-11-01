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
  image_scanning_configuration { scan_on_push = true }
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
  description       = "Allow tcp on port 80"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "task_from_alb" {
  security_group_id            = aws_security_group.tasks_sec.id
  referenced_security_group_id = aws_security_group.alb_sec.id
  description                  = "Allow port 5000 from the load balancer"
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}

resource "aws_vpc_security_group_egress_rule" "task_out" {
  security_group_id = aws_security_group.tasks_sec.id
  description       = "Allow HTTPS out to reach ECR and CloudWatch"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_tasks" {
  security_group_id            = aws_security_group.alb_sec.id
  referenced_security_group_id = aws_security_group.tasks_sec.id
  description                  = "Allow port 5000 to the ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 5000
  to_port                      = 5000
}

resource "aws_lb" "app_lb" {
  name                       = "${var.project_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sec.id]
  subnets                    = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  drop_invalid_header_fields = true
  tags = {
    Name = "${var.project_name}-app-lb"
  }
}
resource "aws_lb_target_group" "alb_target" {
  name        = "${var.project_name}-alb-tg"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target.arn
  }
}

resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-ecs-cluster"

  tags = {
    Name = "${var.project_name}-ecs-cluster"
  }
}
resource "aws_ecs_task_definition" "app_task" {

  family                   = "${var.project_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_role.arn
  skip_destroy             = true
  container_definitions = jsonencode([
    {
      name         = "app"
      image        = "${aws_ecr_repository.ecr_rep.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 5000, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.c_watch.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.tasks_sec.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target.arn
    container_name   = "app"
    container_port   = 5000
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.alb_listener, aws_route.route]
}

resource "aws_eip" "eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.gw]
}
resource "aws_route" "route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id

}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  vpc_id          = aws_vpc.main.id
  service_name    = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private_rt.id]
}

resource "aws_iam_openid_connect_provider" "open_id" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "git_role" {
  name = "${var.project_name}-github-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.open_id.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:yassine-ach@158781609/cloudops-launchpad@1432682729:ref:refs/heads/main"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "git_role_policy" {
  name = "git-role-policy"
  role = aws_iam_role.git_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.ecr_rep.arn
      },
      {
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:DescribeLoadBalancers"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${aws_ecs_cluster.ecs_cluster.name}/${var.project_name}-service"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_sns_topic" "sns_alert" {
  name = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "sns_sub" {
  topic_arn = aws_sns_topic.sns_alert.arn
  protocol  = "email"
  endpoint  = var.contact_email
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = "${var.project_name}-unhealthy-targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.alb_target.arn_suffix
    LoadBalancer = aws_lb.app_lb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.sns_alert.arn]
}
resource "aws_default_security_group" "default_sec_grp" {
  vpc_id = aws_vpc.main.id
}
# Auto-discover public subnets in the VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_security_group" "sg" {
  name        = "strapi-fargate-sg"
  description = "Allow HTTP from public, internal DB access"
  vpc_id      = var.vpc_id

  ingress {
    description = "Strapi HTTP"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "ecs_strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_exec_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name         = "postgres"
      image        = var.db_image
      essential    = true
      portMappings = [{ containerPort = 5432, hostPort = 5432 }]
      environment = [
        { name = "POSTGRES_DB", value = var.db_name },
        { name = "POSTGRES_USER", value = var.db_user },
        { name = "POSTGRES_PASSWORD", value = var.db_pass }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_strapi.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs/postgres"
        }
      }
    },
    {
      name         = "strapi"
      image        = var.strapi_image
      essential    = true
      dependsOn    = [{ containerName = "postgres", condition = "START" }]
      portMappings = [{ containerPort = 1337, hostPort = 1337 }]
      environment = [
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = "127.0.0.1" },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_user },
        { name = "DATABASE_PASSWORD", value = var.db_pass },
        { name = "APP_KEYS", value = var.app_keys },
        { name = "API_TOKEN_SALT", value = var.api_token_salt },
        { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
        { name = "JWT_SECRET", value = var.jwt_secret }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_strapi.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs/strapi"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}

resource "aws_cloudwatch_dashboard" "ecs_strapi" {
  dashboard_name = "strapi-ecs-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.cluster.name, "ServiceName", aws_ecs_service.strapi.name ],
            [ ".", "MemoryUtilization", ".", ".", ".", "." ]
          ],
          period = 300,
          stat = "Average",
          region = var.region,
          title = "ECS Service CPU & Memory Utilization"
        }
      },
      {
        type = "metric",
        x = 0,
        y = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "TaskCount", "ClusterName", aws_ecs_cluster.cluster.name ]
          ],
          period = 300,
          stat = "Average",
          region = var.region,
          title = "ECS Task Count (Container Insights)"
        }
      },
      {
        type = "metric",
        x = 0,
        y = 12,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.cluster.name ],
            [ ".", "NetworkTxBytes", ".", "." ]
          ],
          period = 300,
          stat = "Sum",
          region = var.region,
          title = "ECS Network In/Out (Container Insights)"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "strapi-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm triggers if ECS CPU utilization > 80% for 10 minutes."
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.strapi.name
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_memory" {
  alarm_name          = "strapi-ecs-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm triggers if ECS Memory utilization > 80% for 10 minutes."
  dimensions = {
    ClusterName = aws_ecs_cluster.cluster.name
    ServiceName = aws_ecs_service.strapi.name
  }
}

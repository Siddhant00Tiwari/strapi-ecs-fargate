# 🚀 Strapi ECS Fargate Deployment

This repository contains a Strapi application deployed to AWS ECS Fargate using Terraform and GitHub Actions.

## 📋 Overview

This project demonstrates how to deploy a Strapi CMS application to AWS ECS Fargate using:
- **Terraform** for infrastructure as code
- **GitHub Actions** for CI/CD automation
- **Docker** for containerization
- **AWS ECS Fargate** for serverless container orchestration

## 🔗 Original Repository

This deployment is based on the original Strapi repository with GitHub Actions:
- **Original Repo**: [Strapi GitHub Repository](https://github.com/Siddhant00Tiwari/strapi-ecs-fargate.git)
- **GitHub Actions**: [Strapi GitHub Actions](https://github.com/Siddhant00Tiwari/strapi-ecs-fargate/actions)

## 🏗️ Infrastructure (Terraform)

The Terraform configuration creates a complete ECS Fargate deployment with the following resources:

### Main Infrastructure Components

```hcl
# ECS Cluster with Container Insights
resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Security Group
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

# ECS Task Definition
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
    }
  ])
}

# ECS Service using FARGATE_SPOT
resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    base              = 0
    weight            = 1
  }
  network_configuration {
    subnets          = data.aws_subnets.public.ids
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_strapi" {
  name              = "/ecs/strapi"
  retention_in_days = 14
}

# CloudWatch Dashboard
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

# CloudWatch Alarms
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
```

### Key Features:
- **Multi-container setup**: Strapi + PostgreSQL in the same task
- **Fargate Spot**: Cost-effective compute using FARGATE_SPOT capacity provider
- **Capacity provider strategy**: All tasks run on FARGATE_SPOT (see below for details)
- **Fargate launch type**: Serverless container execution
- **Public subnets**: Auto-discovers public subnets in the VPC
- **Security groups**: Allows HTTP access on port 1337
- **Environment variables**: Secure configuration via GitHub secrets
- **CloudWatch monitoring**: Logs, metrics, dashboard, and alarms
- **Remote state**: S3 backend with native state locking (object lock enabled)

## ⚡️ Fargate Spot & Capacity Provider Strategy

### What is Fargate Spot?
- **Fargate Spot** lets you run ECS tasks at a significant discount compared to standard Fargate pricing.
- **Caveat:** AWS can interrupt (stop) Fargate Spot tasks at any time if capacity is needed elsewhere. Use for workloads that can tolerate interruptions.

### Capacity Provider Strategy in This Project

```hcl
capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  base              = 0
  weight            = 1
}
```
- **All tasks** will be placed on FARGATE_SPOT.
- **base = 0**: No minimum number of tasks required on this provider before using others (not relevant here since only one provider is used).
- **weight = 1**: All tasks go to FARGATE_SPOT (if you had multiple providers, this would control the proportion).

#### What are base and weight?
- **base**: Minimum number of tasks to run on this provider before using others.
- **weight**: Proportion of tasks to place on this provider after the base is satisfied (relative to other providers).

**Example:** If you had both FARGATE and FARGATE_SPOT, you could set base/weight to split tasks between them for cost and reliability.

## 📊 Monitoring & Observability

### CloudWatch Resources Explained

- **CloudWatch Log Group (`aws_cloudwatch_log_group.ecs_strapi`)**
  - Stores all logs from your ECS containers (Strapi and Postgres) in `/ecs/strapi`.
  - Retention is set to 14 days (customizable).

- **CloudWatch Dashboard (`aws_cloudwatch_dashboard.ecs_strapi`)**
  - Visualizes key metrics for your ECS service and cluster.
  - **Widgets include:**
    - **CPU & Memory Utilization:** Standard ECS metrics (AWS/ECS namespace)
    - **Task Count:** From Container Insights (ECS/ContainerInsights namespace)
    - **Network In/Out:** From Container Insights (ECS/ContainerInsights namespace)
  - Lets you monitor service health, scaling, and network activity at a glance.

- **CloudWatch Alarms (`aws_cloudwatch_metric_alarm.ecs_high_cpu`, `ecs_high_memory`)**
  - Alert you if CPU or memory utilization exceeds 80% for 10 minutes.
  - Can be connected to SNS or other notification systems for alerting.

- **Container Insights**
  - Enabled on the ECS cluster for enhanced metrics (TaskCount, NetworkRxBytes, NetworkTxBytes, etc.).
  - Metrics are available in the `ECS/ContainerInsights` namespace and used in the dashboard.

### How to View
- Go to [CloudWatch Dashboards](https://console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:name=strapi-ecs-dashboard)
- You will see widgets for CPU/Memory, Task Count, and Network metrics.
- For logs, go to CloudWatch Logs and search for `/ecs/strapi`.

### Enabling Container Insights
Container Insights is enabled by default in the Terraform ECS cluster resource:
```hcl
resource "aws_ecs_cluster" "cluster" {
  name = "strapi-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
```
If you need to enable it manually:
- AWS Console: ECS > Clusters > strapi-cluster > Monitoring > Enable Container Insights
- AWS CLI: 
  ```bash
  aws ecs update-cluster-settings --cluster strapi-cluster --settings name=containerInsights,value=enabled --region ap-south-1
  ```

## 🔄 CI/CD Pipeline (GitHub Actions)

The GitHub Actions workflow automates the entire deployment process:

### Workflow Steps

```yaml
name: Build and Deploy Strapi to ECS Fargate

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      # 1. Checkout code
      - name: 🧾 Checkout repository
        uses: actions/checkout@v4

      # 2. Docker authentication
      - name: 🔐 Set up Docker auth
        run: echo "${{ secrets.DOCKERHUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin

      # 3. Build and push Docker image
      - name: 🏗️ Build Docker image
        run: docker build -t $DOCKER_IMAGE .
      - name: 📤 Push to Docker Hub
        run: docker push $DOCKER_IMAGE

      # 4. Terraform setup
      - name: 🧰 Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.6.6"

      # 5. AWS configuration
      - name: 🔐 Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      # 6. Create terraform.tfvars from secrets
      - name: 📝 Create terraform.tfvars from secrets
        run: |
          cd terraform
          cat > terraform.tfvars << EOF
          region              = "${{ secrets.AWS_REGION }}"
          vpc_id              = "${{ secrets.AWS_VPC_ID }}"
          ecs_exec_role_arn   = "${{ secrets.AWS_ECS_EXEC_ROLE_ARN }}"
          ecs_task_role_arn   = "${{ secrets.AWS_ECS_TASK_ROLE_ARN }}"
          strapi_image        = "${{ env.DOCKER_IMAGE }}"
          db_image            = "postgres:15"
          db_name             = "${{ secrets.DB_NAME }}"
          db_user             = "${{ secrets.DB_USER }}"
          db_pass             = "${{ secrets.DB_PASSWORD }}"
          app_keys            = "${{ secrets.STRAPI_APP_KEYS }}"
          api_token_salt      = "${{ secrets.STRAPI_API_TOKEN_SALT }}"
          admin_jwt_secret    = "${{ secrets.STRAPI_ADMIN_JWT_SECRET }}"
          jwt_secret          = "${{ secrets.STRAPI_JWT_SECRET }}"
          EOF

      # 7. Deploy infrastructure
      - name: 📁 Setup Terraform working directory
        run: cd terraform && terraform init
      - name: 📋 Terraform Plan
        run: cd terraform && terraform plan -out=tfplan
      - name: 🚀 Terraform Apply
        run: cd terraform && terraform apply -auto-approve tfplan

      # 8. Display resource IDs
      - name: 📋 Display Resource IDs for Import
        run: |
          cd terraform
          echo "🔍 Resource IDs for Local Terraform Import:"
          echo "=========================================="
          echo ""
          echo "ECS Cluster ID:"
          terraform output -raw ecs_cluster_id
          echo ""
          echo "ECS Service ID:"
          terraform output -raw ecs_service_id
          echo ""
          echo "Security Group ID:"
          terraform output -raw security_group_id
          echo ""
          echo "=========================================="
```

### Key Features:
- **Automated builds**: Builds Docker image on every push
- **Secure secrets**: Uses GitHub secrets for sensitive data
- **Infrastructure as Code**: Terraform manages all AWS resources
- **Resource tracking**: Displays resource IDs for local management
- **Manual triggers**: Can be triggered manually via GitHub UI

## 🔐 Required GitHub Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

### AWS Configuration
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (e.g., "us-east-1")
- `AWS_VPC_ID` - VPC ID for deployment
- `AWS_ECS_EXEC_ROLE_ARN` - ECS Task Execution Role ARN
- `AWS_ECS_TASK_ROLE_ARN` - ECS Task Role ARN

### Database Configuration
- `DB_NAME` - PostgreSQL database name
- `DB_USER` - PostgreSQL username
- `DB_PASSWORD` - PostgreSQL password

### Strapi Configuration
- `STRAPI_APP_KEYS` - Strapi APP_KEYS (comma-separated)
- `STRAPI_API_TOKEN_SALT` - Strapi API_TOKEN_SALT
- `STRAPI_ADMIN_JWT_SECRET` - Strapi ADMIN_JWT_SECRET
- `STRAPI_JWT_SECRET` - Strapi JWT_SECRET

### Docker Hub
- `DOCKERHUB_USERNAME` - Docker Hub username
- `DOCKERHUB_PASSWORD` - Docker Hub password

## 🌐 Accessing Your Application

### After Deployment

1. **Get the Public IP**:
   - Go to AWS Console → ECS → Clusters → strapi-cluster
   - Click on the "strapi-service"
   - Find the running task and note the public IP

2. **Access Strapi**:
   ```
   http://<PUBLIC-IP>:1337
   ```

3. **Access Strapi Admin**:
   ```
   http://<PUBLIC-IP>:1337/admin
   ```

### First Time Setup

1. Navigate to `http://<PUBLIC-IP>:1337/admin`
2. Create your first admin user
3. Configure your Strapi application

## 🛠️ Local Development

### Prerequisites
- Node.js 18+
- npm or yarn
- Docker (optional)

### Development Commands

```bash
# Install dependencies
npm install

# Start development server
npm run develop

# Build for production
npm run build

# Start production server
npm run start
```

## 🔧 Troubleshooting

### Common Issues

1. **ECS Service Not Starting**
   - Check ECS task logs in AWS Console
   - Verify all environment variables are set
   - Check security group allows port 1337

2. **Database Connection Issues**
   - Verify PostgreSQL container is running
   - Check database credentials in GitHub secrets
   - Ensure containers can communicate internally

3. **GitHub Actions Failures**
   - Verify all required secrets are configured
   - Check AWS credentials and permissions
   - Ensure VPC and subnets exist

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster strapi-cluster --services strapi-service

# View task logs
aws logs describe-log-groups --log-group-name-prefix /ecs/strapi-task

# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

## 📊 Monitoring

- **ECS Console**: Monitor service health and task status
- **CloudWatch Logs**: View application and container logs
- **CloudWatch Metrics**: Monitor CPU, memory, and network usage

## 🔒 Security Considerations

- All sensitive data is stored as GitHub secrets
- Security group restricts access to necessary ports only
- Database credentials are not exposed in logs
- Use HTTPS in production (requires additional setup)

## 💰 Cost Optimization

- ECS Fargate charges based on actual resource usage
- Consider using Spot instances for non-critical workloads
- Monitor CloudWatch metrics for resource optimization
- Set up billing alerts to track costs

## 📚 Additional Resources

- [Strapi Documentation](https://docs.strapi.io/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights.html)

---

**Note**: This deployment is designed for development and staging environments. For production use, consider additional security measures, monitoring, and backup strategies. 
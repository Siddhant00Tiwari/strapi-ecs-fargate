# Strapi Deployment Workflow

This workflow is implemented in the repository: [Siddhant00Tiwari/strapi](https://github.com/Siddhant00Tiwari/strapi)

## Deployment Guide

This guide explains how to set up and use the GitHub Actions workflow to build and deploy your Strapi application to AWS EC2.

## Overview

The workflow performs the following steps:
1. Builds a Docker image from your Strapi application
2. Pushes the image to Docker Hub
3. Deploys the infrastructure using Terraform
4. Bootstraps the EC2 instance to run your containerized application

## Prerequisites

### 1. AWS Setup
- AWS account with appropriate permissions
- EC2 key pair for SSH access
- VPC with internet connectivity
- IAM user with EC2, VPC, and Security Group permissions

### 2. GitHub Repository Setup
- Repository must be public or have GitHub Actions enabled
- Docker Hub account for container registry

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

### Docker Hub Credentials
- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_PASSWORD`: Your Docker Hub password/token

### AWS Credentials
- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `AWS_REGION`: AWS region (e.g., `ap-south-1`)

### AWS Infrastructure Variables
- `AWS_AMI_ID`: AMI ID for the EC2 instance (e.g., `ami-021a584b49225376d` for Ubuntu 22.04)
- `AWS_INSTANCE_TYPE`: EC2 instance type (e.g., `t2.medium`)
- `AWS_KEY_NAME`: Name of your EC2 key pair (e.g., `ec2-key`)
- `AWS_VPC_ID`: VPC ID where EC2 instance will be launched (e.g., `vpc-009f03c7b686a2073`)

## Configuration Files

### Terraform Variables
The workflow automatically creates `terraform/terraform.tfvars` from your GitHub secrets. The variables are:

```hcl
aws_region    = "ap-south-1"
ami_id        = "ami-021a584b49225376d" # Ubuntu 22.04
instance_type = "t2.medium"
key_name      = "ec2-key"
vpc_id        = "vpc-009f03c7b686a2073" # Use an existing VPC
```

### Docker Configuration
The workflow uses the existing `Dockerfile` in your repository root.

## Workflow Triggers

The workflow is triggered by:
- Push to the `main` branch
- Manual trigger via GitHub Actions UI

## Workflow Steps

1. **Checkout**: Clones your repository
2. **Docker Login**: Authenticates with Docker Hub
3. **Build & Push**: Builds Docker image and pushes to Docker Hub
4. **Terraform Setup**: Initializes Terraform
5. **AWS Configuration**: Sets up AWS credentials
6. **Variables Setup**: Creates terraform.tfvars from GitHub secrets
7. **Infrastructure Deployment**: Creates EC2 instance and security groups
8. **Bootstrap**: Installs Docker and runs your application

## EC2 Instance Details

The Terraform configuration creates:
- EC2 instance with Ubuntu 22.04
- Security group allowing ports 22 (SSH), 80 (HTTP), and 1337 (Strapi)
- Bootstrap script that installs Docker and runs your container

## Accessing Your Application

After deployment, your Strapi application will be available at:
```
http://<EC2-PUBLIC-IP>:1337
```

To find the public IP:
1. Go to AWS Console → EC2 → Instances
2. Look for the instance named "StrapiEC2Instance"
3. Copy the public IP address

## Troubleshooting

### Common Issues

1. **Docker Build Fails**
   - Check your Dockerfile syntax
   - Ensure all dependencies are properly specified

2. **Terraform Apply Fails**
   - Verify AWS credentials are correct
   - Check that the specified VPC and key pair exist
   - Ensure you have sufficient AWS permissions

3. **EC2 Instance Not Accessible**
   - Check security group rules
   - Verify the bootstrap script completed successfully
   - Check EC2 instance logs in AWS Console

### Logs and Debugging

- **GitHub Actions**: Check the Actions tab in your repository
- **EC2 Instance**: SSH into the instance and check `/var/log/strapi-bootstrap.log`
- **Docker Containers**: Run `docker logs strapi-app` on the EC2 instance

## Security Considerations

1. **Secrets Management**: Never commit AWS credentials to your repository
2. **Security Groups**: Consider restricting SSH access to your IP address
3. **Container Registry**: Use private repositories for sensitive applications
4. **IAM Permissions**: Follow the principle of least privilege

## Cost Optimization

- Use appropriate instance types for your workload
- Consider using Spot instances for non-critical deployments
- Monitor your AWS usage and set up billing alerts
- Use AWS Cost Explorer to track expenses

## Next Steps

1. Set up monitoring and logging
2. Configure SSL/TLS certificates
3. Set up automated backups
4. Implement CI/CD for database migrations
5. Add health checks and auto-scaling 
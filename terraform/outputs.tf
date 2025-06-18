output "ecs_cluster" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.cluster.arn
}

output "ecs_cluster_id" {
  description = "The ID of the ECS cluster - use for terraform import"
  value       = aws_ecs_cluster.cluster.id
}

output "ecs_service" {
  description = "The ECS Service name"
  value       = aws_ecs_service.strapi.name
}

output "ecs_service_arn" {
  description = "The ARN of the ECS service"
  value       = aws_ecs_service.strapi.arn
}

output "ecs_service_id" {
  description = "The ID of the ECS service - use for terraform import"
  value       = aws_ecs_service.strapi.id
}

output "ecs_task_definition" {
  description = "The name of the ECS task definition"
  value       = aws_ecs_task_definition.strapi.family
}

output "ecs_task_definition_revision" {
  description = "The revision of the ECS task definition"
  value       = aws_ecs_task_definition.strapi.revision
}

output "security_group" {
  description = "The name of the security group"
  value       = aws_security_group.sg.name
}

output "security_group_id" {
  description = "The ID of the security group - use for terraform import"
  value       = aws_security_group.sg.id
}

output "security_group_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.sg.arn
}

output "vpc_id" {
  description = "The VPC ID where resources are deployed"
  value       = var.vpc_id
}

output "subnets" {
  description = "The subnets where the ECS service is deployed"
  value       = data.aws_subnets.public.ids
}

output "strapi_image" {
  description = "The Docker image used for Strapi"
  value       = var.strapi_image
}

output "database_image" {
  description = "The Docker image used for the database"
  value       = var.db_image
}

output "database_name" {
  description = "The database name"
  value       = var.db_name
  sensitive   = true
}

output "database_user" {
  description = "The database username"
  value       = var.db_user
  sensitive   = true
}

output "service_url" {
  description = "The URL to access the Strapi service (you'll need to get the public IP from ECS console)"
  value       = "http://<public-ip>:1337"
}

output "deployment_info" {
  description = "Summary of the deployment"
  value = {
    cluster_name    = aws_ecs_cluster.cluster.name
    service_name    = aws_ecs_service.strapi.name
    task_definition = aws_ecs_task_definition.strapi.family
    security_group  = aws_security_group.sg.name
    vpc_id          = var.vpc_id
    strapi_image    = var.strapi_image
    database_image  = var.db_image
  }
}

output "import_commands" {
  description = "Terraform import commands to run locally"
  value = {
    ecs_cluster = "terraform import aws_ecs_cluster.cluster ${aws_ecs_cluster.cluster.id}"
    ecs_service = "terraform import aws_ecs_service.strapi ${aws_ecs_service.strapi.id}"
    security_group = "terraform import aws_security_group.sg ${aws_security_group.sg.id}"
  }
}

output "resource_ids" {
  description = "All resource IDs for importing into local Terraform state"
  value = {
    ecs_cluster_id = aws_ecs_cluster.cluster.id
    ecs_service_id = aws_ecs_service.strapi.id
    security_group_id = aws_security_group.sg.id
  }
}

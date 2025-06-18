variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_id" {
  description = "VPC ID for the ECS service"
  type        = string
}

variable "ecs_exec_role_arn" {
  description = "ARN of the existing ECS Task Execution Role"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ARN of the existing ECS Task Role"
  type        = string
}

variable "strapi_image" {
  description = "Docker image for Strapi"
  type        = string
  default     = "siddocker467/strapi-app:latest"
}

variable "db_image" {
  description = "Docker image for Postgres"
  type        = string
  default     = "postgres:15"
}

variable "db_name" {
  description = "Postgres database name"
  type        = string
  default     = "strapi_db"
}

variable "db_user" {
  description = "Postgres username"
  type        = string
  default     = "strapi_user"
}

variable "db_pass" {
  description = "Postgres password"
  type        = string
  default     = "strapi_pass"
}

variable "app_keys" {
  description = "Strapi APP_KEYS (comma-separated)"
  type        = string
}

variable "api_token_salt" {
  description = "Strapi API_TOKEN_SALT"
  type        = string
}

variable "admin_jwt_secret" {
  description = "Strapi ADMIN_JWT_SECRET"
  type        = string
}

variable "jwt_secret" {
  description = "Strapi JWT_SECRET"
  type        = string
}

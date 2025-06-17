variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name for EC2 access"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EC2 instance will be launched"
  type        = string
}

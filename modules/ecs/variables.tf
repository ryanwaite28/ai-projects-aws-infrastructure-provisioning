variable "project" {
  description = "Project name used as a prefix in resource names and tags."
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)."
  type        = string
}

variable "region" {
  description = "AWS region for this module's resources."
  type        = string
}

# ── Cluster ───────────────────────────────────────────────────────────────────

variable "cluster_name" {
  description = "Short name for the ECS cluster. Full name: {project}-{environment}-{region_short}-ecs-{cluster_name}."
  type        = string
  default     = "main"
}

variable "cluster_only" {
  description = "If true, create only the ECS cluster and no service/task resources. Used by the platform stack."
  type        = bool
  default     = false
}

variable "container_insights_enabled" {
  description = "Enable CloudWatch Container Insights on the ECS cluster."
  type        = bool
  default     = true
}

variable "execute_command_enabled" {
  description = "Enable ECS Exec for interactive debugging of running containers."
  type        = bool
  default     = true
}

# ── Service ───────────────────────────────────────────────────────────────────

variable "service_name" {
  description = "Short name for the ECS service. Required when cluster_only = false."
  type        = string
  default     = null
}

variable "cluster_arn" {
  description = "ARN of an existing ECS cluster to deploy the service into. When set, skips cluster creation."
  type        = string
  default     = null
}

variable "desired_count" {
  description = "Desired number of running task instances."
  type        = number
  default     = 2
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent during deployments."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum percent of tasks during rolling deployments."
  type        = number
  default     = 200
}

variable "enable_deployment_circuit_breaker" {
  description = "Enable the ECS deployment circuit breaker with automatic rollback."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID for the service's security group."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for ECS tasks (private subnets recommended)."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Additional security group IDs to attach to ECS tasks."
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP to Fargate tasks (only needed if tasks are in public subnets without NAT)."
  type        = bool
  default     = false
}

# ── Task Definition ───────────────────────────────────────────────────────────

variable "task_cpu" {
  description = "CPU units for the Fargate task (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Memory in MiB for the Fargate task."
  type        = number
  default     = 1024
}

variable "task_execution_role_arn" {
  description = "ARN of the ECS task execution role (ECR pull, Secrets Manager, CloudWatch Logs)."
  type        = string
  default     = null
}

variable "task_role_arn" {
  description = "ARN of the ECS task role (application-level AWS API access)."
  type        = string
  default     = null
}

variable "container_definitions" {
  description = "JSON-encoded container definitions for the task. See AWS docs for schema."
  type        = string
  default     = "[]"
}

variable "volumes" {
  description = "List of volume configurations to attach to the task definition."
  type = list(object({
    name      = string
    host_path = optional(string, null)
    efs_volume_configuration = optional(object({
      file_system_id     = string
      root_directory     = optional(string, "/")
      access_point_id    = optional(string, null)
      iam_auth           = optional(bool, false)
    }), null)
  }))
  default = []
}

# ── Load Balancer ─────────────────────────────────────────────────────────────

variable "target_group_arn" {
  description = "ARN of the ALB target group to register this service with."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Name of the container in the task definition to register with the target group."
  type        = string
  default     = "app"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

# ── Auto Scaling ──────────────────────────────────────────────────────────────

variable "autoscaling_enabled" {
  description = "Enable Application Auto Scaling for the service."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum number of tasks for auto-scaling."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of tasks for auto-scaling."
  type        = number
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto-scaling."
  type        = number
  default     = 70
}

variable "autoscaling_memory_target" {
  description = "Target memory utilization percentage for auto-scaling."
  type        = number
  default     = 80
}

variable "log_retention_days" {
  description = "CloudWatch log group retention in days."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The VPC ID to deploy the ECS cluster"
  type        = string
}

variable "subnets" {
  description = "The Subnets to deploy the ECS services"
  type        = list(string)
}

variable "ecs_sg" {
  description = "The Security Group to assign to the ECS services"
  type        = string
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

resource "aws_ecs_cluster" "main" {
  name = "main-ecs-cluster"
}

resource "aws_ecs_task_definition" "main" {
  family                = "my-task"
  container_definitions = jsonencode([{
    name  = "my-container"
    image = "nginx"
    cpu   = 256
    memory = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
}

resource "aws_ecs_service" "main" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 2

  network_configuration {
    subnets          = var.subnets
    security_groups  = [var.ecs_sg]
    assign_public_ip = true
  }

  launch_type = "EC2"
}

resource "aws_appautoscaling_target" "ecs_service" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

resource "aws_appautoscaling_policy" "scale_down" {
  name               = "scale-down"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_service.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_service.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_service.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 25.0
  }
}

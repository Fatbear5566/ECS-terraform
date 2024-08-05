output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnets" {
  value = module.vpc.subnets
}

output "ecs_sg" {
  value = module.security_groups.ecs_sg
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

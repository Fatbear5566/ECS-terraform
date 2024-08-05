provider "aws" {
  region = "us-west-2"
}

module "vpc" {
  source = "./vpc"
}

module "security_groups" {
  source = "./security_groups"
  vpc_id = module.vpc.vpc_id
}

module "ecs_cluster" {
  source = "./ecs_cluster"
  vpc_id = module.vpc.vpc_id
  subnets = module.vpc.subnets
  ecs_sg = module.security_groups.ecs_sg
}

resource "aws_ecs_cluster" "main" {
  name = "rollie-dev-cluster"
}

data "template_file" "app" {
  template = file("templates/app.json")

  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
    env_name       = var.env_name
    aws_account_id = data.aws_caller_identity.current.account_id
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "rollie-dev-task"
  execution_role_arn       = "${aws_iam_role.ecs_execution_role.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  container_definitions    = data.template_file.app.rendered
}

resource "aws_ecs_service" "main" {
  name            = "rollie-dev-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = aws_subnet.public.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.app.id
    container_name   = "rollie-dev"
    container_port   = var.app_port
  }

  depends_on = [aws_alb_listener.frontend]
}

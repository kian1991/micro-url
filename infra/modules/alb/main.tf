
resource "aws_security_group" "public-http-alb" {
  name        = "alb-sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "this" {
  name               = "micro-url-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public-http-alb.id]
  subnets            = var.public_subnets

  tags = {
    Name = "micro-url-alb"
  }
}





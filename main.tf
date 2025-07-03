# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values for consistent resource naming and tagging
locals {
  name_prefix = "tailscale"
  
  common_tags = merge(var.tags, {
    Name      = "${local.name_prefix}-instance"
    ManagedBy = "terraform"
    Service   = "tailscale"
  })
}

# IAM role for EC2 instance
resource "aws_iam_role" "tailscale_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-role"
  })
}

# Attach basic EC2 permissions to the IAM role
resource "aws_iam_role_policy_attachment" "tailscale_ssm" {
  role       = aws_iam_role.tailscale_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile for EC2
resource "aws_iam_instance_profile" "tailscale_profile" {
  name = "${local.name_prefix}-ec2-profile"
  role = aws_iam_role.tailscale_role.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2-profile"
  })
}

# Security group for Tailscale instance
resource "aws_security_group" "tailscale_sg" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for Tailscale instance"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tailscale UDP port
  ingress {
    description = "Tailscale"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

# User data script for Tailscale installation and configuration
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    tailscale_auth_key = var.tailscale_auth_key
  }))
}

# EC2 instance for Tailscale
resource "aws_instance" "tailscale" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.tailscale_sg.id]
  subnet_id              = var.subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.tailscale_profile.name

  user_data                   = local.user_data
  user_data_replace_on_change = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-root-volume"
    })
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for the Tailscale instance
resource "aws_eip" "tailscale_eip" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-eip"
  })

  depends_on = [aws_instance.tailscale]
}

# Associate Elastic IP with the instance
resource "aws_eip_association" "tailscale_eip_assoc" {
  instance_id   = aws_instance.tailscale.id
  allocation_id = aws_eip.tailscale_eip.id
}
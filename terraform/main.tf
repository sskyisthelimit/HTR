resource "aws_ecr_repository" "htr_api_repo" {
  name = "htr-api-repo"
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.htr_api_repo.name

  policy = <<EOF
  {
      "rules": [
          {
              "rulePriority": 1,
              "description": "Keep only the last 2 images",
              "selection": {
                  "tagStatus": "any",
                  "countType": "imageCountMoreThan",
                  "countNumber": 2
              },
              "action": {
                  "type": "expire"
              }
          }
      ]
  }
  EOF
}


data "aws_iam_policy_document" "ecr_access_policy_doc" {
  statement {
    sid    = "AllowECRAccess"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecr_access_policy" {
  name   = "ECRAccessPolicy"
  policy = data.aws_iam_policy_document.ecr_access_policy_doc.json
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "htr-api-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_access_policy.arn
}

resource "aws_route53_zone" "htr_api_zone" {
  name = "htr-api.xyz"
  tags = {
    Name = "htr-api-zone"
  }
}

resource "aws_vpc" "htr_api_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "htr-api-vpc" 
  }
}

resource "aws_subnet" "htr_api_subnet" {
  vpc_id = aws_vpc.htr_api_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "htr-api-subnet"
  }

}

resource "aws_internet_gateway" "htr_api_igw" {
  vpc_id = aws_vpc.htr_api_vpc.id
  tags = {
    Name = "htr-api-igw"
  }
}

resource "aws_route_table" "htr_api_route_table" {
  vpc_id = aws_vpc.htr_api_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.htr_api_igw.id
  }
}

resource "aws_route_table_association" "htr_api_route_table_assoc" {
  subnet_id = aws_subnet.htr_api_subnet.id
  route_table_id = aws_route_table.htr_api_route_table.id
}

resource "aws_security_group" "htr_api_sg" {  
  vpc_id = aws_vpc.htr_api_vpc.id
  tags = {
    Name = "htr-api-sg"
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
} 

resource "aws_eip" "htr_api_eip" {
  domain = "vpc"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "htr-api-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_launch_template" "htr_api_launch_template" {
  name_prefix   = "htr-api-launch-template"
  image_id      = "ami-0c79aa53926826e57"
  instance_type = "g4dn.xlarge"
  key_name      = "htr-api-key"
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.htr_api_sg.id]
    subnet_id                   = aws_subnet.htr_api_subnet.id
  }

  user_data = base64encode(<<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

$(aws ecr get-login --no-include-email --region ${var.region})
docker pull ${aws_ecr_repository.htr_api_repo.repository_url}:latest
docker run -d -p 8000:8000 ${aws_ecr_repository.htr_api_repo.repository_url}:latest

aws ec2 associate-address --allocation-id ${aws_eip.htr_api_eip.id} --instance-id $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --allow-reassociation
EOF
)

}

resource "aws_autoscaling_group" "htr_api_asg" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.htr_api_subnet.id]
  health_check_grace_period = 300
  health_check_type    = "EC2"
  tag {
    key                 = "Name"
    value               = "htr-api-backend"
    propagate_at_launch = true
  }
  mixed_instances_policy {
    instances_distribution {
      spot_max_price = "0.23"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.htr_api_launch_template.id
        version = "$Latest"
      }
    }
  }
}

resource "aws_route53_record" "htr_api_dns_record" {
  zone_id = aws_route53_zone.htr_api_zone.zone_id
  name    = "htr-api"
  type    = "A"
  ttl     = 300
  records = [aws_eip.htr_api_eip.public_ip]
}
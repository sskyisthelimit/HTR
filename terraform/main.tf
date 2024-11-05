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


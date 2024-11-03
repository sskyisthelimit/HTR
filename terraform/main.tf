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

resource "aws_iam_user_policy" "cost_management_policy" {
  name   = "CostManagementPolicy"
  user   = aws_iam_user.my_user.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "aws-portal:ViewBilling",              # View billing details
          "ce:GetCostAndUsage",                  # View cost and usage reports
          "ce:GetCostForecast",                  # View cost forecasts
          "ce:GetReservationCoverage",           # View reservation coverage
          "ce:GetReservationUtilization",        # View reservation utilization
          "ce:GetRightsizingRecommendation",     # View rightsizing recommendations
          "ce:GetSavingsPlansCoverage",          # View savings plan coverage
          "ce:GetSavingsPlansUtilization",       # View savings plan utilization
          "ce:ListCostCategoryDefinitions",      # List cost categories
          "cur:DescribeReportDefinitions",       # View cost and usage report definitions
          "cur:GetCostAndUsageReport",           # Access detailed cost and usage reports
          "ce:GetDimensionValues",               # View dimension values for cost reports
          "ce:GetCostCategories",                # View cost categories
          "servicecatalog:SearchProvisionedProducts", # View used services in console
          "tag:GetResources"                     # View resource tagging information
        ]
        Resource = "*"
      }
    ]
  })
}

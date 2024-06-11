resource "aws_iam_role" "lambdaRole2" {
  name = "lambdaRole2"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambdaEC2policy" {
  name = "lambdaEC2policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : "ec2:*",
        "Effect" : "Allow",
        "Resource" : "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "lambdaRolePolicyAttachment" {
  policy_arn = aws_iam_policy.lambdaEC2policy.arn
  roles      = [aws_iam_role.lambdaRole2.name]
  name       = "lambdaRolePolicyAttachment"
}

resource "aws_key_pair" "demo-key" {
  key_name   = "demo-key"
  public_key = file("${path.module}/demo-key.pub")
}

data "archive_file" "lambdaFile" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "createEC2" {
  role          = aws_iam_role.lambdaRole2.arn
  filename      = data.archive_file.lambdaFile.output_path
  function_name = "createEC2"
  runtime       = "python3.9"
  handler       = "lambda.lambda_handler"
  environment {
    variables = {
      AMI="ami-08a0d1e16fc3f61ea"
      INSTANCE_TYPE="t2.micro"
      KEY_NAME="demo-key"
    }
  }
}

resource "aws_lambda_invocation" "lambdaTest" {
  function_name = aws_lambda_function.createEC2.function_name

  input = jsonencode({
  })


}

output "result_entry" {
  value = jsondecode(aws_lambda_invocation.lambdaTest.result)
}
resource "aws_sqs_queue" "image_queue" {
  name                        = "image-generation-queue-20"
  message_retention_seconds   = 86400
  visibility_timeout_seconds  = 60
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role-20"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "20-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::pgr301-couch-explorers/20/*",
          "arn:aws:s3:::pgr301-couch-explorers"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.image_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "image_generator_lambda_20" {
  function_name    = "image-generator-lambda-20"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "lambda_sqs.lambda_handler"
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  timeout = 60

  environment {
    variables = {
      BUCKET_NAME = "pgr301-couch-explorers"
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_event" {
  event_source_arn = aws_sqs_queue.image_queue.arn
  function_name    = aws_lambda_function.image_generator_lambda_20.arn
  batch_size       = 10
}
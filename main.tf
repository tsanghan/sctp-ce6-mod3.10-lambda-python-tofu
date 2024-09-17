# S3 Bucket
resource "aws_s3_bucket" "myBucket" {
  bucket = "tsanghan-ce6-serverless-s3-bucket-python"
}

# SNS Topic and Subscription
resource "aws_sns_topic" "SuperTopic" {
  name = "MyCustomTopic-python"
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.SuperTopic.arn
  protocol  = "email"
  endpoint  = "tsanghan@gmail.com"
}

# SQS Queue
resource "aws_sqs_queue" "MyQueue" {
  name = "tsanghan-ce6-Q-python"
}

# IAM Role and Policies for Lambda Functions
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "lambda_exec_role-tsanghan-ce6"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.SuperTopic.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.MyQueue.arn]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type = "zip"

  source_file = "${path.module}/app.py"
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda Functions
resource "aws_lambda_function" "hello" {
  function_name = "tsanghan-ce6-hello-tofu"
  runtime       = "python3.12"
  handler       = "app.hello"
  filename      = data.archive_file.lambda_zip.output_path
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      CLASS_NAME = "sctp-ce6"
      SNS_ARN    = aws_sns_topic.SuperTopic.arn
    }
  }
}

resource "aws_lambda_function" "hello2" {
  function_name = "tsanghan-ce6-hello2-tofu"
  runtime       = "python3.12"
  handler       = "app.hello2"
  filename      = data.archive_file.lambda_zip.output_path
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      CLASS_NAME = "sctp-ce6"
      SNS_ARN    = aws_sns_topic.SuperTopic.arn
    }
  }
}

resource "aws_lambda_function" "hello3" {
  function_name = "tsanghan-ce6-hello3-tofu"
  runtime       = "python3.12"
  handler       = "app.hello3"
  filename      = data.archive_file.lambda_zip.output_path
  role          = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      CLASS_NAME = "sctp-ce6"
      SNS_ARN    = aws_sns_topic.SuperTopic.arn
    }
  }
}

# API Gateway Setup
resource "aws_apigatewayv2_api" "api" {
  name          = "MyApi"
  protocol_type = "HTTP"
}

# Integrations and Routes for 'hello' Function
resource "aws_apigatewayv2_integration" "hello_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.hello.invoke_arn
}

resource "aws_apigatewayv2_route" "hello_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_integration.id}"
}

# Integrations and Routes for 'hello2' Function
resource "aws_apigatewayv2_integration" "hello2_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.hello2.invoke_arn
}

resource "aws_apigatewayv2_route" "hello2_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /hello2"
  target    = "integrations/${aws_apigatewayv2_integration.hello2_integration.id}"
}

# Integrations and Routes for 'hello3' Function
resource "aws_apigatewayv2_integration" "hello3_integration" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.hello3.invoke_arn
}

resource "aws_apigatewayv2_route" "hello3_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /hello3"
  target    = "integrations/${aws_apigatewayv2_integration.hello3_integration.id}"
}

# API Stage
resource "aws_apigatewayv2_stage" "api_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
}

# Permissions for API Gateway to Invoke Lambda Functions
resource "aws_lambda_permission" "hello_permission" {
  statement_id  = "AllowAPIGatewayInvokeHello"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

resource "aws_lambda_permission" "hello2_permission" {
  statement_id  = "AllowAPIGatewayInvokeHello2"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello2.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

resource "aws_lambda_permission" "hello3_permission" {
  statement_id  = "AllowAPIGatewayInvokeHello3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*"
}

# S3 Bucket Notification to Trigger 'hello' Function
resource "aws_lambda_permission" "s3_permission" {
  statement_id  = "AllowS3InvokeHello"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.myBucket.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.myBucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.hello.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_lambda_permission.s3_permission]
}

# SQS Event Source Mapping for 'hello2' Function
resource "aws_lambda_event_source_mapping" "hello2_sqs" {
  event_source_arn                   = aws_sqs_queue.MyQueue.arn
  function_name                      = aws_lambda_function.hello2.function_name
  batch_size                         = 10
  maximum_batching_window_in_seconds = 60
  function_response_types            = ["ReportBatchItemFailures"]
}

# SNS Subscription to Trigger 'hello3' Function
resource "aws_lambda_permission" "sns_permission" {
  statement_id  = "AllowSNSInvokeHello3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello3.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.SuperTopic.arn
}

resource "aws_sns_topic_subscription" "hello3_sns_subscription" {
  topic_arn = aws_sns_topic.SuperTopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.hello3.arn
}

output "hello" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "filename" {
  value = data.archive_file.lambda_zip.output_path
}


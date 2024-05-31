provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:*",
          "dynamodb:*"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "create_lambda" {
  type        = "zip"
  source_file = "${path.module}/bin/create"
  output_path = "${path.module}/bin/create.zip"
}

data "archive_file" "read_lambda" {
  type        = "zip"
  source_file = "${path.module}/bin/read"
  output_path = "${path.module}/bin/read.zip"
}

data "archive_file" "update_lambda" {
  type        = "zip"
  source_file = "${path.module}/bin/update"
  output_path = "${path.module}/bin/update.zip"
}

data "archive_file" "delete_lambda" {
  type        = "zip"
  source_file = "${path.module}/bin/delete"
  output_path = "${path.module}/bin/delete.zip"
}

data "archive_file" "handler_lambda" {
  type        = "zip"
  source_file = "${path.module}/bin/handler"
  output_path = "${path.module}/bin/handler.zip"
}

resource "aws_lambda_function" "create" {
  function_name = "createFunction"
  handler       = "create"
  runtime       = "go1.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.create_lambda.output_path
}

resource "aws_lambda_function" "read" {
  function_name = "readFunction"
  handler       = "read"
  runtime       = "go1.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.read_lambda.output_path
}

resource "aws_lambda_function" "update" {
  function_name = "updateFunction"
  handler       = "update"
  runtime       = "go1.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.update_lambda.output_path
}

resource "aws_lambda_function" "delete" {
  function_name = "deleteFunction"
  handler       = "delete"
  runtime       = "go1.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.delete_lambda.output_path
}

resource "aws_lambda_function" "handler" {
  function_name = "handlerFunction"
  handler       = "handler"
  runtime       = "go1.x"
  role          = aws_iam_role.lambda_exec.arn
  filename      = data.archive_file.handler_lambda.output_path
}

resource "aws_api_gateway_rest_api" "crud_api" {
  name        = "CRUD API"
  description = "CRUD API for managing items in DynamoDB"
}

resource "aws_api_gateway_resource" "items_resource" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  parent_id   = aws_api_gateway_rest_api.crud_api.root_resource_id
  path_part   = "items"
}

resource "aws_api_gateway_method" "create_method" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.items_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "read_method" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.items_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "update_method" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.items_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_method" {
  rest_api_id   = aws_api_gateway_rest_api.crud_api.id
  resource_id   = aws_api_gateway_resource.items_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_integration" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  resource_id = aws_api_gateway_resource.items_resource.id
  http_method = aws_api_gateway_method.create_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.create.invoke_arn
}

resource "aws_api_gateway_integration" "read_integration" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  resource_id = aws_api_gateway_resource.items_resource.id
  http_method = aws_api_gateway_method.read_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.read.invoke_arn
}

resource "aws_api_gateway_integration" "update_integration" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  resource_id = aws_api_gateway_resource.items_resource.id
  http_method = aws_api_gateway_method.update_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.update.invoke_arn
}

resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  resource_id = aws_api_gateway_resource.items_resource.id
  http_method = aws_api_gateway_method.delete_method.http_method
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri         = aws_lambda_function.delete.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.create_integration,
    aws_api_gateway_integration.read_integration,
    aws_api_gateway_integration.update_integration,
    aws_api_gateway_integration.delete_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.crud_api.id
  stage_name  = "dev"
}

resource "aws_dynamodb_table" "items" {
  name           = "MyTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_api_gateway_rest_api" "process_file_api_gateway" {
  name                         = "process-file-api-gateway"
  disable_execute_api_endpoint = false
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_resource" "presigned_url_resource" {
  rest_api_id = aws_api_gateway_rest_api.process_file_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.process_file_api_gateway.root_resource_id
  path_part   = "generate-presigned-url"
}



resource "aws_api_gateway_method" "presigned_url_resource_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.process_file_api_gateway.id
  resource_id   = aws_api_gateway_resource.presigned_url_resource.id
  http_method   = "GET"
  authorization = "NONE"

}

resource "aws_api_gateway_integration" "presigned_url_resource_get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.process_file_api_gateway.id
  resource_id             = aws_api_gateway_resource.presigned_url_resource.id
  http_method             = aws_api_gateway_method.presigned_url_resource_get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.generate_presigned_url_lambda.invoke_arn
  credentials             = aws_iam_role.presigned_url_role.arn
  depends_on              = [aws_api_gateway_method.presigned_url_resource_get_method]
}

# Method Response(200)
resource "aws_api_gateway_method_response" "presigned_url_resource_method_response" {
  rest_api_id = aws_api_gateway_rest_api.process_file_api_gateway.id
  resource_id = aws_api_gateway_resource.presigned_url_resource.id
  http_method = aws_api_gateway_method.presigned_url_resource_get_method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Strict-Transport-Security" = true
  }
}

# Integration Response(200)
resource "aws_api_gateway_integration_response" "presigned_url_resource_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.process_file_api_gateway.id
  resource_id = aws_api_gateway_resource.presigned_url_resource.id
  http_method = aws_api_gateway_method.presigned_url_resource_get_method.http_method
  status_code = "200"

  depends_on = [aws_api_gateway_integration.presigned_url_resource_get_integration]
}



resource "aws_api_gateway_deployment" "my_deployment" {
  rest_api_id = aws_api_gateway_rest_api.process_file_api_gateway.id

  triggers = {
    # Force redeployment when API config changes
    redeploy = sha1(jsonencode({
      resource   = aws_api_gateway_resource.presigned_url_resource.id
      method     = aws_api_gateway_method.presigned_url_resource_get_method.id
      integration = aws_api_gateway_integration.presigned_url_resource_get_integration.id
    }))
  }

  depends_on = [
    aws_api_gateway_integration.presigned_url_resource_get_integration
  ]
}


resource "aws_api_gateway_stage" "my_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.process_file_api_gateway.id
  deployment_id = aws_api_gateway_deployment.my_deployment.id
}

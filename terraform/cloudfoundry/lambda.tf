data "archive_file" "zip" {
  type        = "zip"
  source_file  = "${path.module}/lambda/ShieldEngagementLambda.js"
  output_path = "${path.module}/lambda/ShieldEngagementLambda.zip"
}

data "aws_iam_role" "ddos_lambda" {
  name               = "ddos_lambda_assume_role"
}

resource "aws_lambda_function" "ddos_lambda" {
  filename         = "${path.module}/lambda/ShieldEngagementLambda.zip"
  function_name    = "ShieldEngagementLambda"
  role             = data.aws_iam_role.ddos_lambda.arn
  handler          = "exports.handler"
  source_code_hash = data.archive_file.zip.output_base64sha256
  runtime          = "nodejs12.x"
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ddos_lambda.function_name
  principal     = "sns.amazonaws.com"
}

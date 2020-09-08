resource "aws_iam_policy" "vault_dynamodb_access" {
  policy = templatefile("${path.module}/policies/dynamodb_access.json.tpl", {
    dynamodb_arn = aws_dynamodb_table.vault_data.arn
  })
  name        = "${var.env}-vault-dynamodb-access"
  description = "Grants rights to access DynamoDB tables as required by Vault"
}


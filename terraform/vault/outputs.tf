output "vault_dynamodb_name" {
  value = aws_dynamodb_table.vault-data.id
}

output "vault_dynamodb_arn" {
  value = aws_dynamodb_table.vault-data.arn
}

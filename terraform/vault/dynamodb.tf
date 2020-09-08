/*
 * FIXME: Deployer-concourse does not currently have sufficient privilege
 * (write-access) to Dynamo
 * resource "aws_dynamodb_table" "vault_data" {
 *   name           = "${var.env}-vault-data"
 *   billing_mode   = "PAY_PER_REQUEST"
 *   hash_key       = "Path"
 *   range_key      = "Key"
 *
 *   attribute {
 *     name = "Path"
 *     type = "S"
 *   }
 *
 *   attribute {
 *     name = "Key"
 *     type = "S"
 *   }
 *
 *   tags = {
 *     Name = "${var.env}-vault-data"
 *   }
 * }
*/

data "archive_file" "cleanup_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/${var.name_prefix}.zip"
}

resource "aws_iam_role" "test2" {
  assume_role_policy = "lala"
  dynamic "tag" {
    for_each = ""
    content {
      value = ["test", "test1", "test2"]
    }
  }
}

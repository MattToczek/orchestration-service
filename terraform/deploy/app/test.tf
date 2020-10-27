provider "aws" {
  region = "eu-west-2"
}

resource "aws_iam_role" "no_tags" {
  assume_role_policy = "test"

}

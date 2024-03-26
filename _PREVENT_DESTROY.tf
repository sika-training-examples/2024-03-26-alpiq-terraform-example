resource "null_resource" "PREVENT_DESTROY" {
  lifecycle {
    prevent_destroy = true
  }
  depends_on = [
    aws_s3_bucket.aaa,
  ]
}

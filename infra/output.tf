output "vpc_id" {
  value = aws_vpc.main.id
}

output "s3_bucket_name" {
    value = aws_s3_bucket.models.bucket
}

output "ecr_repository_url" {
    value = aws_ecr_repository.api.repository_url
}

output "ec2_public_ip" {
    value = aws_instance.api.public_ip
}
output "cloudperf_internal_ip" {
  value = aws_instance.cloudperf.private_ip
}

output "cloudperf_external_ip" {
  value = aws_instance.cloudperf.public_ip
}

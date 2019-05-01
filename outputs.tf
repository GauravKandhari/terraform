output "address" {
  value = "${aws_elb.nginx.dns_name}"
}

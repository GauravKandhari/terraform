provider "aws" {
  region = "${var.aws_region}"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "lb" {
  vpc_id = "${aws_vpc.default.id}"
  name = "assignement-elb"
  description = "Security group for ELB"


  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
 }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
 }
}


resource "aws_security_group" "default" {
  vpc_id = "${aws_vpc.default.id}"
  name = "assignement-securitygroup"
  description = "Security group for instances"

  ingress {
    from_port    = 22
    to_port      = 22
    protocol     = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
 }

  ingress {
    from_port    = 80
    to_port      = 80
    protocol     = "tcp"
    cidr_blocks  = ["10.0.0.0/16"]
 }

  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
 }

}

resource "aws_elb" "nginx" {
  name = "assignement-elb"

  subnets   = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.lb.id}"]
  instances       = ["${aws_instance.web.*.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
 }

}

#
resource "aws_key_pair" "authentication" {
  key_name   = "test"
 # public_key = "${file("/root/terraform/id_rsa.pub")}"
   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfhI2klqPn9NwFockMatcTJgUmEWzqjJJIu9NRlMGzLMto6sO2kS+o2KhKSAsDtVf08NKBj3t1eBWNzRlcpygXgXF9JNe3EWcRoFgIT15aefHhdEi5+yHx1LR6Nanb2Er4huuzDEfNsw901tV3RgQAnhUhtAK8qnj9p8qnTdOMhQlCL8PuAtbaFTbGpx74rcp0RkNOhcYhhGA8SvmEWgXNqV2CRdzuLn0rUPVc5NfT1OntybBst+81Dno17O+WwmYiIV/g+CoDNEBqR/8xSWy8tjRNQv2ftvEjII20XA7wl0QbE94JSAvwn+tcGkmJNRg+gtzK+0IYVbOmaczhbU3X root@ip-172-31-20-143"

}


resource "aws_instance" "web" {
  connection {
    user  = "ubuntu"
    agent = false

 }

  count  =  3
  instance_type  = "t2.micro"
  ami   = "ami-007d5db58754fa284"
#  key_name = "${aws_key_pair.authentication.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # Same Subnet as of ELB.

  subnet_id = "${aws_subnet.default.id}"

  # Running remote provisioner on instances to install nginx

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]
}

}


resource "aws_vpc" "cloudperf" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_internet_gateway" "cloudperf" {
  vpc_id = aws_vpc.cloudperf.id
}

resource "aws_security_group" "ingress_ssh" {
  name   = "ingress-ssh"
  vpc_id = aws_vpc.cloudperf.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route_table" "cloudperf" {
  vpc_id = aws_vpc.cloudperf.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudperf.id
  }
}

resource "aws_route_table_association" "cloudperf" {
  subnet_id      = aws_subnet.cloudperf.id
  route_table_id = aws_route_table.cloudperf.id
}

resource "aws_subnet" "cloudperf" {
  vpc_id            = aws_vpc.cloudperf.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.availability_zone

  tags = {
    Name = "Cloudperf"
  }
}

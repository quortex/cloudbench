resource "aws_key_pair" "cloudperf" {
  key_name   = var.ssh_user
  public_key = file(var.ssh_pub_key_file)
}

data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = [format("debian-10-%s*", var.arch)]
  }

  owners = ["136693071363"]
}


resource "aws_instance" "cloudperf" {
  ami               = data.aws_ami.debian.id
  instance_type     = var.instance_type
  availability_zone = var.availability_zone

  subnet_id       = aws_subnet.cloudperf.id
  security_groups = [aws_security_group.ingress_ssh.id]

  key_name                    = aws_key_pair.cloudperf.key_name
  associate_public_ip_address = true

  tags = {
    Name = "CloudPerf"
  }
}

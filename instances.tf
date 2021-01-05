# data source for getting the latest nginx instance

data "aws_ami" "aws-linux" {
  provider    = aws.my_region
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Creating the keypair for accessing instance

resource "aws_key_pair" "nginx-key" {
  provider   = aws.my_region
  key_name   = "nginx-key"
  public_key = file("~/.ssh/id_rsa.pub")
}



#Creating the aws instance for nginx

resource "aws_instance" "nginx1" {
  provider                    = aws.my_region
  ami                         = "ami-0be2609ba883822ec"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.terra_pub1.id
  vpc_security_group_ids      = [aws_security_group.nginx_allow.id]
  key_name                    = aws_key_pair.nginx-key.key_name
  tags = {
    Name = "terraform-instance"
  }

}


resource "null_resource" "copy_execute" {

  connection {
    type        = "ssh"
    host        = aws_instance.nginx1.public_ip
    user        = "ec2-user"
    private_key = file("/home/cloud_user/.ssh/id_rsa")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
    ]
  }
  depends_on = [aws_instance.nginx1]
}



output "aws_instance_public_dns" {
  value = aws_instance.nginx1.public_dns
}

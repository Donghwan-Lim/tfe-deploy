terraform {
  cloud {
    hostname = "app.terraform.io"
    organization = "Insideinfo"
    workspaces {
      name = "tfe-deploy"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "tfe-vpc" {
  cidr_block = "192.168.10.0/24"
  enable_dns_hostnames = true
  tags = {
    "Name" = "${var.prefix}-VPC"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_subnet" "tfe-subnet" {
  vpc_id            = aws_vpc.tfe-vpc.id
  cidr_block        = "192.168.10.0/25"
  availability_zone = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.prefix}-Subnet"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_subnet" "tfe-subnet2" {
  vpc_id            = aws_vpc.tfe-vpc.id
  cidr_block        = "192.168.10.128/25"
  availability_zone = "${var.region}c"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.prefix}-Subnet-2"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.tfe-vpc.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_route_table" "tfe-rt" {
  vpc_id = aws_vpc.tfe-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

tags = {
    Name = "${var.prefix}-Public-RT"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_route_table_association" "PRT-PSN1" {
  subnet_id      = aws_subnet.tfe-subnet.id
  route_table_id = aws_route_table.tfe-rt.id
}

resource "aws_route_table_association" "PRT-PSN2" {
  subnet_id      = aws_subnet.tfe-subnet2.id
  route_table_id = aws_route_table.tfe-rt.id
}

resource "aws_security_group" "tfe-sg" {
  name = "${var.prefix}-security-group"
  vpc_id = aws_vpc.tfe-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8800
    to_port     = 8800
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  /*
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }*/

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    #prefix_list_ids = []
  }
   /*
   egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    #prefix_list_ids = []
  }*/

#KB Capital Security Setting
/* 
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }
*/

  tags = {
    Name = "${var.prefix}-security-group"
    environment = "${var.prefix}-Labs"
  }
}

########EC2 Instance#########
/*resource "aws_eip" "tfe-eip" {
  instance = aws_instance.tfe-server.id
  vpc      = true
  tags = {
    Name = "tfe-eip"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_eip_association" "tfe-eip" {
  instance_id   = aws_instance.tfe-server.id
  allocation_id = aws_eip.tfe-eip.id
}
*/
# Create Volumes
resource "aws_ebs_volume" "tfe-vols" {
  availability_zone = aws_subnet.tfe-subnet.availability_zone
  size              = 100
  type = "gp3"
  tags = {
    Name = "tfe-volumes"
    environment = "${var.prefix}-Labs"
  }
}

# Attach Volumes
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.tfe-vols.id
  instance_id = aws_instance.tfe-server.id
}

resource "aws_instance" "tfe-server" {

  ami = "ami-035233c9da2fabf52"

  subnet_id = aws_subnet.tfe-subnet.id
  instance_type = var.instance_type1
  associate_public_ip_address = true
  # security_groups = [ aws_security_group.tfe-sg.id]
  vpc_security_group_ids = [ aws_security_group.tfe-sg.id ]
  key_name = aws_key_pair.tfe-keypair.key_name
  root_block_device {
    volume_type = "gp3"
    volume_size = 50
  }

  tags = {
    Name = "${var.prefix}-server"
    environment = "${var.prefix}-Labs"
  }
}

#####KEY_PAIR#######
resource "tls_private_key" "tfe-priv-key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "tfe-keypair" {
  key_name   = "${var.prefix}-keypair"
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAxnyAkgOuZKikOax2ZAutclzsG+2geDCUL4FMgoEMrY6qvLDIfV85Hf55gJlZwjzqvcXpg+xdBi4/Zr0kxjzQwlqfn5c4F1XltHs+YFz92ie+KIv++Y4DYhnlea3SrwwyN+eiQu/AKpZWkpAWyJ3Axw4U1RavJKxtlBYPrZXKQ+b4mlpQJopr5lU8jF6Uu61GTNPQ2mN9zQ1QQe93p6dhWyvdirlQ0OW/Hpab6ae+k8HxpoTVre+nuIRS/tBKfD+rNNblXIM2n5Kn4abYzNLyxBTxCJDK+lkUhmuAfC9D9GJR8fbvHaplYhp8/Jz9L0vEZG7/BYq6n8+cRaKNVBwSeQ=="
  public_key = tls_private_key.tfe-priv-key.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${var.prefix}-keypair.pem"
  content = tls_private_key.tfe-priv-key.private_key_pem
}

#########Command EXEC###########
/*
  resource "null_resource" "configure_tfe" {
  depends_on = [aws_eip_association.tfe-eip]

  triggers = {
    build_number = timestamp()
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update",
      "sudo amazon-linux-extras install epel -y",
      "sudo yum install -y certbot",
      "sudo hostnamectl set-hostname aws-tfe-server",
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = tls_private_key.tfe-priv-key.private_key_pem
      host        = aws_eip.tfe-eip.public_ip
    }
  }
}*/
#########Command EXEC###########

####################### S3 ############
/*
resource "aws_s3_bucket" "tfe-s3" {
  bucket = "tfe-s3"

  tags = {
    Name        = "tfe-s3"
    environment = "${var.prefix}-Labs"
  }
}
*/

################ ALB ##################
resource "aws_lb" "tfe-alb" {
  name               = "${var.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [ aws_security_group.tfe-sg.id ]
  #vpc_security_group_ids = [ aws_security_group.tfe-sg.id ]
  subnets            = [aws_subnet.tfe-subnet.id, aws_subnet.tfe-subnet2.id]

  enable_deletion_protection = true
  /*
  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "test-lb"
    enabled = true
  }
  */
  tags = {
    Name = "${var.prefix}-alb"
    environment = "${var.prefix}-Labs"
  }
}

resource "aws_lb_listener" "alb-listner-443" {
  load_balancer_arn = aws_lb.tfe-alb.arn
  port = "443"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:ap-northeast-2:421448405988:certificate/9ae4eb34-7db6-45ca-8a6a-f9e88150c2e7"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.TG-443.arn
  }
}

resource "aws_lb_listener" "alb-listner-8800" {
  load_balancer_arn = aws_lb.tfe-alb.arn
  port = "8800"
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:ap-northeast-2:421448405988:certificate/9ae4eb34-7db6-45ca-8a6a-f9e88150c2e7"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.TG-8800.arn
  }
}

resource "aws_lb_listener" "alb-listner-80" {
  load_balancer_arn = aws_lb.tfe-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#################Route 53 Record###########
resource "aws_route53_record" "alb-alias" {
  zone_id = "Z07221033KQJ2V7LHSBCM"
  name    = "kbcapital.inside-terraform.com"
  type    = "A"

  alias {
    name                   = aws_lb.tfe-alb.dns_name
    zone_id                = aws_lb.tfe-alb.zone_id
    evaluate_target_health = false
  }
}

################## TG #################
resource "aws_lb_target_group" "TG-443" {
  name = "${var.prefix}-TG-443"
  port = "443"
  protocol = "HTTPS"
  vpc_id = aws_vpc.tfe-vpc.id

  health_check {
    enabled = true
    matcher = "200-399"
    path = "/_health_check"
    protocol = "HTTPS"
    port = "443"
  }
}

resource "aws_lb_target_group_attachment" "tfe-alb-tg-443" {
  target_group_arn = aws_lb_target_group.TG-443.arn
  target_id        = aws_instance.tfe-server.id
  port             = "443"
}

resource "aws_lb_target_group" "TG-8800" {
  name = "${var.prefix}-TG-8800"
  port = "8800"
  protocol = "HTTPS"
  vpc_id = aws_vpc.tfe-vpc.id

  health_check {
    enabled = true
    matcher = "200-399"
    path = "/"
    protocol = "HTTPS"
    port = "8800"
  }
}

resource "aws_lb_target_group_attachment" "tfe-alb-tg-8800" {
  target_group_arn = aws_lb_target_group.TG-8800.arn
  target_id        = aws_instance.tfe-server.id
  port             = "8800"
}
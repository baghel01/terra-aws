provider "aws"{
  region="ap-south-1"
  profile="Shreyash"
}
resource "aws_key_pair" "pass" {
  key_name   = "task1-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 shreyash.baghel01_2017@galgotiasuniversity.edu.in"
}

resource "aws_security_group" "firstSG" {
  name        = "firstSG"
  description = "first task"
  vpc_id      = "vpc-fc594594"

  ingress {
    from_port   = 443
    to_port     = 443
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "firstSG"
  }
}
resource "aws_instance" "first"{
  ami="ami-0447a12f28fddb066"
  instance_type="t2.micro"
  key_name="task1-key"
  security_groups=["${aws_security_group.firstSG.name}"]
  tags = {
    Name = "first"
  }
provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd -y,
      "sudo yum install php -y",
      "sudo yum install git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd"
    ]
  }

}
resource "aws_ebs_volume" "task1_ebs" {
  availability_zone = aws_instance.first.availability_zone
  size = 1
  tags = {
    Name = "task1_ebs"
  }
}
resource "aws_volume_attachment" "task1_att" {
  device_name = "/dev/sdt"
  volume_id   = aws_ebs_volume.task1_ebs.id
  instance_id = aws_instance.first.id
  force_detach = true
}


resource "aws_s3_bucket" "task1-bucket20" {
  bucket = "task1-bucket20"
  acl    = "private"
  region = "ap-south-1"
  tags = {
    Name = "task1-bucket"
  }
}


locals {
  s3_origin_id = "task1-s3-origin"
}


resource "aws_s3_bucket_object" "task1-bucket20" {
  bucket = "task1-bucket20"
  key    = "task1.jpg"
  source = "task1.jpg"
}


resource "aws_s3_bucket_public_access_block" "public" {
  bucket = "task1-bucket20"


  block_public_acls   = false
  block_public_policy = false
} 
  
resource "aws_cloudfront_distribution" "cdn_task1" {
  origin {
    domain_name = aws_s3_bucket.task1-bucket20.bucket_regional_domain_name
    origin_id   = local.s3_origin_id


    custom_origin_config {
      http_port = 80
      https_port = 80
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  
  enabled = true


  default_cache_behavior {
    allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id


    forwarded_values {
      query_string = false


      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "allow-all"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "null_resource" "mount" {


  depends_on = [
    aws_volume_attachment.task1_att,
  ]

  provisioner "remote-exec"{
    inline = [
      "sudo mkfs.ext4 /dev/xvda",
      "sudo mount /dev/xvda /var/www/html",
      "sudo rm -rf /var/www/html",
      "sudo git clone https://github.com/baghel01/terra-aws.git /var/www/html",
    ]
  }
}



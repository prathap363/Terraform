# EKS EFS CSI DRIVER 
resource "aws_security_group" "efs" {
  name        = "eks-efs"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "nfs"
    from_port        = 2049
    to_port          = 2049
    protocol         = "TCP"
    cidr_blocks      = [var.cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# EKS EFS CSI DRIVER 
resource "aws_security_group" "db" {
  name        = "eks-db"
  description = "Allow traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    description = "PostgreSQL access from within VPC"
    protocol         = "TCP"
    cidr_blocks      = [var.cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

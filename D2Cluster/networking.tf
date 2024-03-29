resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name       = var.project_name
    managed-by = "terraform"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name       = "${var.project_name}-Internet gateway"
    managed-by = "terraform"
  }
}


resource "aws_eip" "nat_gateway_elasticip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {

  allocation_id = aws_eip.nat_gateway_elasticip.id
  subnet_id     = aws_subnet.public[0].id


  tags = {
    Name = "${var.project_name}-NAT Gateway"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.ig]
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name       = "${var.project_name}-public"
    managed-by = "terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name       = "${var.project_name}-private"
    managed-by = "terraform"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat.id
}

resource "aws_subnet" "public" {
  count = length(var.zones)

  vpc_id = aws_vpc.main.id

  cidr_block        = cidrsubnet(var.cidr-public, 4, count.index)
  availability_zone = "${var.aws_region}${element(var.zones, count.index)}"

  map_public_ip_on_launch = true

  tags = {
    Name       = "${var.project_name}-public"
    managed-by = "terraform"
  }
}


resource "aws_subnet" "private" {
  count = length(var.zones)

  vpc_id = aws_vpc.main.id

  cidr_block        = cidrsubnet(var.cidr-private, 4, count.index)
  availability_zone = "${var.aws_region}${element(var.zones, count.index)}"

  map_public_ip_on_launch = true

  tags = {
    Name       = "${var.project_name}-private"
    managed-by = "terraform"
  }
}


resource "aws_route_table_association" "public" {
  count = length(var.zones)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "private" {
  count = length(var.zones)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}


resource "aws_security_group" "administration" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.trusted_network]
  }

  ingress {
    from_port   = 12443
    to_port     = 12443
    protocol    = "tcp"
    cidr_blocks = [var.trusted_network]
  }

  ingress {
    from_port   = 12343
    to_port     = 12343
    protocol    = "tcp"
    cidr_blocks = [var.trusted_network]
  }
}

resource "aws_security_group" "servers" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 9243
    to_port     = 9243
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9343
    to_port     = 9343
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "internal" {
  vpc_id = aws_vpc.main.id

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }
}


resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.project_name}-${var.rds_instance_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

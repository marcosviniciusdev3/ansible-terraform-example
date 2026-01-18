resource "aws_vpc" "webserver_net" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  region               = var.default_region

  tags = {
    Name      = "Webserver Network"
    ManagedBy = "terraform"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.webserver_net.id

  tags = {
    Name      = "Webserver Internet Gateway"
    ManagedBy = "terraform"
  }
}

# Subnet privada
resource "aws_subnet" "private_net" {
  vpc_id            = aws_vpc.webserver_net.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.az1

  tags = {
    Name      = "Private"
    ManagedBy = "terraform"
  }
}

# Subnet pública
resource "aws_subnet" "public_net" {
  vpc_id                  = aws_vpc.webserver_net.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = var.az1

  tags = {
    Name      = "Public Network"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.webserver_net.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_net.id
  route_table_id = aws_route_table.public_rt.id
}

# CIDR Cheatsheet
# var.cidr                 : VPC      : 10.0.0.0/20
# cidrsubnet(var.cidr,2,0) : Public   : 10.0.0.0/22
# cidrsubnet(var.cidr,4,0) : Public-a : 10.0.0.0/24
# cidrsubnet(var.cidr,4,1) : Public-b : 10.0.1.0/24
# cidrsubnet(var.cidr,4,2) : Public-c : 10.0.2.0/24
# cidrsubnet(var.cidr,2,1) : Priv     : 10.0.4.0/22
# cidrsubnet(var.cidr,4,4) : Priv-a   : 10.0.4.0/24
# cidrsubnet(var.cidr,4,5) : Priv-b   : 10.0.5.0/24
# cidrsubnet(var.cidr,4,6) : Priv-c   : 10.0.6.0/24
#------------------------------------------#
# Data Sources
#------------------------------------------#
data "aws_region" "region" {
}

#------------------------------------------#
# VPC
#------------------------------------------#
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment-name}-VPC"
  }
}

#------------------------------------------#
# VPC Common Resources
#------------------------------------------#
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.vpc.id
  subnet_ids = flatten([
    aws_subnet.public_a.*.id,
    aws_subnet.private_a.*.id,
  ])

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # Blackhole traffic to the real opd.com
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "deny"
    cidr_block = "75.126.101.246/32"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "ICG Network ACL"
  }
}

resource "aws_key_pair" "icg-jenkins" {
  key_name   = "${var.vpc_display_name}-icg-jenkins"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCT4dN7Z9UhDW3KEZ5gVQpU6J6iL+hjZ8AHmD4W3zPNMlaRMuIETmq1Gnn3Fw7VFgLqZMY5oCJdgUGVyRZxAJ7eoJTUuUQvl0veAu+R0CkpAtAXutCKHiE7KQCXdJAeIJ8MBwIC1v6Q/4xzI4Za0G1JyCreo+XHpxcpQhFSDtIq4DWHtgKc8HRjTQv5CY4Mo+0LEXGz7M7aC7WbuJMKPZ4XDnPKR7uFaNPQP3e92RERpTpSdok9u+WkahEnR5eEFmQvfb8WWEdo9N/KKSiYAjCJcql4C06GAz2mqzhxWaxn+j6k9ndeZzlnaXJKquTBt6POm6Cys0JHJ/i+7Jt4yN8X icg-jenkins"
}

resource "aws_vpc_dhcp_options" "icg_internal" {
  domain_name_servers = [
    "AmazonProvidedDNS",
  ]

  tags = {
    Name = "${var.vpc_display_name}-DNS-Internal"
  }
}

resource "aws_vpc_dhcp_options_association" "icg_internal" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.icg_internal.id
}

resource "aws_security_group" "http_https_public_sg" {
  vpc_id      = aws_vpc.vpc.id
  name        = "http_https_public"
  description = "Allowed public traffic from public Internet to http https"

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "http_https_public"
  }
}

resource "aws_security_group" "stage-env-sg" {
  vpc_id      = aws_vpc.vpc.id
  name        = "stage-env-sg"
  description = "Allowed traffic from ICG Internal Subnets"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1
    cidr_blocks = [
      "172.16.0.0/13",
      var.cidr,
      var.aws_vpn_west_cidr,
      var.aws_vpn_east_cidr,
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "icg-internal"
  }
}

resource "aws_security_group" "icg_all_sg" {
  vpc_id      = aws_vpc.vpc.id
  name        = "icg-all-environments"
  description = "Allowed traffic from ICG Internal Subnets"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["172.16.0.0/13"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "stage-all-environments"
  }
}


#------------------------------------------#
# VPC Public Networking
#------------------------------------------#
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_display_name}-IGW"
  }
}

resource "aws_route_table" "route_public" {
  vpc_id           = aws_vpc.vpc.id
  propagating_vgws = [aws_vpn_gateway.vgw.id]

  tags = {
    Name = "${var.vpc_display_name}-Public"
  }
}

resource "aws_route" "default_public" {
  route_table_id         = aws_route_table.route_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  depends_on             = [aws_route_table.route_public]
}

#- Public -#
resource "aws_subnet" "public_a" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr, 4, count.index)
  availability_zone = "${data.aws_region.region.id}${element(var.azs, count.index)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_display_name}-Public-${element(var.azs, count.index)}"
  }
}

resource "aws_route_table_association" "public_a" {
  count          = 3
  subnet_id      = aws_subnet.public_a[count.index].id
  route_table_id = aws_route_table.route_public.id
}

#------------------------------------------#
# VPC NAT
#------------------------------------------#
resource "aws_nat_gateway" "nat_a" {
  count         = var.nat_per_az ? 3 : 1
  allocation_id = aws_eip.nat_a[count.index].id
  subnet_id     = aws_subnet.public_a[count.index].id

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat_a" {
  count = var.nat_per_az ? 3 : 1
}

#------------------------------------------#
# VPC Private Networking
#------------------------------------------#
resource "aws_vpn_gateway" "vgw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.vpc_display_name}-VGW"
  }
}

resource "aws_vpc_endpoint" "private_s3" {
  vpc_id          = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.region.id}.s3"
  route_table_ids = aws_route_table.route_private.*.id
}

resource "aws_route_table" "route_private" {
  count            = var.nat_per_az ? 3 : 1
  vpc_id           = aws_vpc.vpc.id
  propagating_vgws = [aws_vpn_gateway.vgw.id]

  tags = {
    Name = "${var.vpc_display_name}-Private-${element(var.azs, count.index)}"
  }
}

resource "aws_route" "default_private" {
  count                  = var.nat_per_az ? 3 : 1
  route_table_id         = aws_route_table.route_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_a[count.index].id
}

# Default to using a private route table for security
resource "aws_main_route_table_association" "vpc_main_rt" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.route_private[0].id
}

#- Private -#
resource "aws_subnet" "private_a" {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr, 4, 4 + count.index)
  availability_zone = "${data.aws_region.region.id}${element(var.azs, count.index)}"

  tags = {
    Name = "${var.vpc_display_name}-Private-${element(var.azs, count.index)}"
  }
}

resource "aws_route_table_association" "private_a" {
  count          = 3
  subnet_id      = aws_subnet.private_a[count.index].id
  route_table_id = aws_route_table.route_private[count.index].id
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

# EC2 Subnet - Primary
resource "aws_subnet" "public-primary-instance" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-a"
  }
}

# EC2 Subnet - Secondary
resource "aws_subnet" "public-secondary-instance" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-b"
  }
}

# RDS Subnet - Primary
resource "aws_subnet" "rds-priamry-instance" {
  count                   = var.rds_port > 0 ? 1 : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.3.0/24"
  availability_zone       = "${var.region}c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-c"
  }
}

# RDS Subnet - Secondary
resource "aws_subnet" "rds-secondary-instance" {
  count                   = var.rds_port > 0 ? 1 : 0
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.1.4.0/24"
  availability_zone       = "${var.region}d"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name}-subnet-d"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gate_w" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-Internet-gateway"
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}


# Route table
# Routing all subnet to the internet
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gate_w.id
  }

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_route_table_association" "public_instance-a" {
  subnet_id      = aws_subnet.public-primary-instance.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "public_instance-b" {
  subnet_id      = aws_subnet.public-secondary-instance.id
  route_table_id = aws_route_table.route-table.id
}


resource "aws_route_table_association" "RDS_c" {
  count          = var.rds_port > 0 ? 1 : 0
  subnet_id      = aws_subnet.rds-priamry-instance[0].id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_route_table_association" "RDS_d" {
  count          = var.rds_port > 0 ? 1 : 0
  subnet_id      = aws_subnet.rds-secondary-instance[0].id
  route_table_id = aws_route_table.route-table.id
}


# Security Groups
#Instances - Allowing ports 80 & 443 & 22
resource "aws_security_group" "allow_tcp" {
  name        = "${var.name}_allow_tcp"
  description = "Allow TCP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "allow_TCP"
    Ports = "80/443/22"
  }
}
# Inbound
resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_tcp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_tcp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_tcp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
# Outbound
resource "aws_vpc_security_group_egress_rule" "instacne_allow_all_egress" {
  security_group_id = aws_security_group.allow_tcp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# staging - Allowing ports 80 & 443 & 22
resource "aws_security_group" "allow_access_staging" {
  count       = var.staging_resource_count == true ? 1 : 0
  name        = "${var.name}-staging-allow_inbound"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "inbound"
    Ports = "80/443/22"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_staging" {
  count             = var.staging_resource_count == true ? 1 : 0
  security_group_id = aws_security_group.allow_access_staging[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_staging" {
  count             = var.staging_resource_count == true ? 1 : 0
  security_group_id = aws_security_group.allow_access_staging[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_staging" {
  count             = var.staging_resource_count == true ? 1 : 0
  security_group_id = aws_security_group.allow_access_staging[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "instacne_allow_all_egress_staging" {
  count             = var.staging_resource_count == true ? 1 : 0
  security_group_id = aws_security_group.allow_access_staging[count.index].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Database - Allowing port for mySQL
resource "aws_security_group" "rds" {
  count       = var.rds_port > 0 ? 1 : 0
  name        = "RDS"
  description = "Allow access to RDS engine"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "port"
    Ports = "${var.rds_port}"
  }
}
# Ingress
resource "aws_vpc_security_group_ingress_rule" "allow_database" {
  count             = var.rds_port > 0 ? 1 : 0
  security_group_id = aws_security_group.rds[0].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.rds_port
  ip_protocol       = "tcp"
  to_port           = var.rds_port
}
# Outgress
resource "aws_vpc_security_group_egress_rule" "allow_database_egress" {
  count             = var.rds_port > 0 ? 1 : 0
  security_group_id = aws_security_group.rds[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Security Group - Application Load Balancer
#Instances - Allowing ports 80 & 443
resource "aws_security_group" "load_balancer" {
  name        = "load_balancer_allow_access"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Name  = "HTTP"
    Ports = "80"
  }
}
# Ingress
resource "aws_vpc_security_group_ingress_rule" "loadbalancer_allow_http" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "loadbalancer_allow_https" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Outgress
resource "aws_vpc_security_group_egress_rule" "loadbalance_allow_all_egress" {
  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


/*
# ACLs
# ACL for RDS
resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = [aws_subnet.rds-priamry-instance.id]

  egress {
    protocol   = "-1"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = var.rds_port
    to_port    = var.rds_port
  }

  tags = {
    Name = "${var.name}"
  }
}
*/

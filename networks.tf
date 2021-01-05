#create the VPC in US-East-1

resource "aws_vpc" "my_vpc" {
  provider             = aws.my_region
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "Deployed by Terraform"
  }

}


#Creating the data resource for getting the az's in the region
data "aws_availability_zones" "azs" {
  provider = aws.my_region
  state    = "available"

}

#Creating the subnets two public and 2 private

resource "aws_subnet" "terra_pub1" {
  provider          = aws.my_region
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "192.168.1.0/26"
  tags = {
    "Name" = "terra_pub1"
  }

}

resource "aws_subnet" "terra_pub2" {
  provider          = aws.my_region
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "192.168.1.64/26"
  tags = {
    "Name" = "terra_pub2"
  }

}

resource "aws_subnet" "terra_priv1" {
  provider          = aws.my_region
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "192.168.1.128/26"
  tags = {
    "Name" = "terra_priv1"
  }

}

resource "aws_subnet" "terra_priv2" {
  provider          = aws.my_region
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "192.168.1.192/26"
  tags = {
    "Name" = "terra_priv2"
  }

}



#Adding the IGW for the VPC

resource "aws_internet_gateway" "igw" {
  provider = aws.my_region
  vpc_id   = aws_vpc.my_vpc.id


}

# Adding the Elastic ip

resource "aws_eip" "nat" {
  provider = aws.my_region

}

#Adding NAT GW

resource "aws_nat_gateway" "nat_gw" {
  provider      = aws.my_region
  subnet_id     = aws_subnet.terra_pub1.id
  allocation_id = aws_eip.nat.id
  tags = {
    Name = "gw NAT"
  }

}



#Create the public route tables

resource "aws_route_table" "pub_rt" {
  provider = aws.my_region
  vpc_id   = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "pub_rt"
  }

}


#Create the private route tables

resource "aws_route_table" "priv_rt_1" {
  provider = aws.my_region
  vpc_id   = aws_vpc.my_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "priv_rt_1"
  }

}

resource "aws_route_table" "priv_rt_2" {
  provider = aws.my_region
  vpc_id   = aws_vpc.my_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }
  tags = {
    Name = "priv_rt_2"
  }

}


#Associating the subnets to private and public route tables

#Associating the subnets to private and public route tables

resource "aws_route_table_association" "associate_public_route1" {
  provider       = aws.my_region
  route_table_id = aws_route_table.pub_rt.id
  subnet_id      = aws_subnet.terra_pub1.id

}


resource "aws_route_table_association" "associate_public_route2" {
  provider       = aws.my_region
  route_table_id = aws_route_table.pub_rt.id
  subnet_id      = aws_subnet.terra_pub2.id

}

resource "aws_route_table_association" "associate_private_route1" {
  provider       = aws.my_region
  route_table_id = aws_route_table.priv_rt_1.id
  subnet_id      = aws_subnet.terra_priv1.id

}

resource "aws_route_table_association" "associate_private_route2" {
  provider       = aws.my_region
  route_table_id = aws_route_table.priv_rt_2.id
  subnet_id      = aws_subnet.terra_priv2.id

}


#Creating the Security group for nginx server to allow access

resource "aws_security_group" "nginx_allow" {
  provider = aws.my_region
  vpc_id   = aws_vpc.my_vpc.id
  #SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}





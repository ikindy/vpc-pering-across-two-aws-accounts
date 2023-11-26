# Define the provider for the first AWS account
provider "aws" {
  region = "us-west-1"
}

# Create the VPC in the first AWS account
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "my-vpc"
    Environment = "production"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name        = "public-subnet-1"
    Environment = "production"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name        = "public-subnet-2"
    Environment = "production"
  }
}

# Define the provider for the second AWS account
provider "aws" {
  alias  = "account2"
  region = "us-west-1"
  assume_role {
    role_arn = "arn:aws:iam::<account_id>:role/<role_name>"  # Replace with actual account ID and role name
  }
}

# Reference the existing VPC in the second AWS account
data "aws_vpcs" "vpcs_account2" {
  provider = aws.account2
}

resource "aws_subnet" "public_subnet_1_account2" {
  provider                  = aws.account2  
  vpc_id     = data.aws_vpcs.vpcs_account2.ids[0]
  cidr_block = "172.31.32.0/24"

  tags = {
    Name        = "public-subnet-1-account2"
    Environment = "production"
  }
}

resource "aws_subnet" "public_subnet_2_account2" {
  provider                  = aws.account2
  vpc_id     = data.aws_vpcs.vpcs_account2.ids[0]
  cidr_block = "172.31.48.0/24"

  tags = {
    Name        = "public-subnet-2-account2"
    Environment = "production"
  }
}

# Create the peering connection
resource "aws_vpc_peering_connection" "peering" {
  provider = aws

  depends_on     = [aws_vpc.vpc, data.aws_vpcs.vpcs_account2]
  peer_vpc_id    = data.aws_vpcs.vpcs_account2.ids[0]
  vpc_id         = aws_vpc.vpc.id
  auto_accept    = false
  peer_region    = "us-west-1"
  peer_owner_id  = "<peer_account_id>"  # Replace with actual peer account ID
}

# Create the peering connection accepter
resource "aws_vpc_peering_connection_accepter" "accepter" {
  provider                  = aws.account2
  vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  auto_accept               = true
}

# Create a route table in the first VPC (account1)
resource "aws_route_table" "route_table_account1" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block                = "10.1.0.0/16"  # Replace with the actual CIDR block of the second VPC (account2)
    vpc_peering_connection_id = aws_vpc_peering_connection.peering.id
  }

  tags = {
    Name = "peering-route-table-account1"
  }

  depends_on = [aws_vpc_peering_connection.peering]
}

# Associate the route table with the public subnets in the first VPC (account1)
resource "aws_route_table_association" "association_account1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.route_table_account1.id

  depends_on = [aws_route_table.route_table_account1]
}

resource "aws_route_table_association" "association_2_account1" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.route_table_account1.id

  depends_on = [aws_route_table.route_table_account1]
}

# Create a route table in the second VPC (account2)
resource "aws_route_table" "route_table_account2" {
  vpc_id = data.aws_vpcs.vpcs_account2.ids[0]

  route {
    cidr_block                = "10.0.0.0/16"  # Replace with the actual CIDR block of the first VPC (account1)
    vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter.id
  }

  tags = {
    Name = "peering-route-table-account2"
  }

  provider = aws.account2  # Specify the provider alias here

  depends_on = [aws_vpc_peering_connection_accepter.accepter]
}

# Associate the route table with the public subnets in the second VPC (account2)
resource "aws_route_table_association" "association_account2" {
  subnet_id      = aws_subnet.public_subnet_1_account2.id
  route_table_id = aws_route_table.route_table_account2.id

  provider = aws.account2  # Specify the provider alias here

  depends_on = [aws_route_table.route_table_account2]
}

resource "aws_route_table_association" "association_2_account2" {
  subnet_id      = aws_subnet.public_subnet_2_account2.id
  route_table_id = aws_route_table.route_table_account2.id

  provider = aws.account2  # Specify the provider alias here

  depends_on = [aws_route_table.route_table_account2]
}

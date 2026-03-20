##################################################################################
## Cross-Region VPC Peering (optional, for Aurora Global)
##
## Only created when enable_global_cluster = true AND create_vpc_peering = true.
## Skip this if your VPCs are already connected (Transit Gateway, existing peering, VPN).
##################################################################################

data "aws_vpc" "primary" {
  count = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  id    = var.primary_vpc_id
}

data "aws_vpc" "dr" {
  count    = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  provider = aws.secondary
  id       = var.dr_vpc_id
}

data "aws_route_tables" "primary" {
  count  = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  vpc_id = var.primary_vpc_id

  filter {
    name   = "association.main"
    values = ["false"]
  }
}

data "aws_route_tables" "dr" {
  count    = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  provider = aws.secondary
  vpc_id   = var.dr_vpc_id

  filter {
    name   = "association.main"
    values = ["false"]
  }
}

resource "aws_vpc_peering_connection" "primary_to_dr" {
  count       = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  vpc_id      = var.primary_vpc_id
  peer_vpc_id = var.dr_vpc_id
  peer_region = var.dr_region
  auto_accept = false
  tags        = { Name = "${var.cluster_name}-primary-to-dr" }
}

resource "aws_vpc_peering_connection_accepter" "dr_accept" {
  count                     = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
  auto_accept               = true
  tags                      = { Name = "${var.cluster_name}-primary-to-dr" }
}

resource "aws_vpc_peering_connection_options" "primary" {
  count                     = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.dr_accept[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "dr" {
  count                     = var.enable_global_cluster && var.create_vpc_peering ? 1 : 0
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.dr_accept[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "primary_to_dr" {
  for_each                  = var.enable_global_cluster && var.create_vpc_peering ? toset(data.aws_route_tables.primary[0].ids) : toset([])
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.dr[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
}

resource "aws_route" "dr_to_primary" {
  for_each                  = var.enable_global_cluster && var.create_vpc_peering ? toset(data.aws_route_tables.dr[0].ids) : toset([])
  provider                  = aws.secondary
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.primary[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
}

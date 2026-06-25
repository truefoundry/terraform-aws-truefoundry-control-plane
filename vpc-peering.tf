##################################################################################
## Cross-region VPC peering (optional, for Aurora Global Database)
##
## Only created when ALL of these are true:
##   - truefoundry_aurora_enable_global_cluster = true
##   - truefoundry_aurora_secondary_config       set
##   - truefoundry_aurora_vpc_peering_enabled   = true
##
## Aurora Global Database replication itself does NOT need this — AWS
## replicates between regions over its own backbone. Enable peering when
## resources in one VPC must reach the database endpoint in the other VPC
## privately (e.g. primary-VPC apps reading from the DR reader endpoint,
## cross-region operators, monitoring).
##
## Requires non-overlapping VPC CIDRs.
##################################################################################

data "aws_vpc" "peering_primary" {
  count = local.vpc_peering_enabled ? 1 : 0
  id    = var.vpc_id
}

data "aws_vpc" "peering_secondary" {
  count    = local.vpc_peering_enabled ? 1 : 0
  provider = aws.secondary
  id       = var.truefoundry_aurora_secondary_config.vpc_id
}

resource "aws_vpc_peering_connection" "primary_to_dr" {
  count       = local.vpc_peering_enabled ? 1 : 0
  vpc_id      = var.vpc_id
  peer_vpc_id = var.truefoundry_aurora_secondary_config.vpc_id
  peer_region = data.aws_region.secondary[0].region
  auto_accept = false
  tags = merge(
    local.tags,
    var.truefoundry_aurora_secondary_config.tags,
    { Name = "${local.truefoundry_aurora_unique_name}-primary-to-dr" }
  )
}

resource "aws_vpc_peering_connection_accepter" "secondary" {
  count                     = local.vpc_peering_enabled ? 1 : 0
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
  auto_accept               = true
  tags = merge(
    local.tags,
    var.truefoundry_aurora_secondary_config.tags,
    { Name = "${local.truefoundry_aurora_unique_name}-primary-to-dr" }
  )
}

##################################################################################
## Cross-VPC private DNS resolution (optional but recommended).
## Uses the accepter's connection ID so both sides wait for the peering to be
## accepted before configuring options.
##################################################################################

resource "aws_vpc_peering_connection_options" "primary" {
  count                     = local.vpc_peering_enabled && var.truefoundry_aurora_vpc_peering_allow_remote_dns_resolution ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.secondary[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "secondary" {
  count                     = local.vpc_peering_enabled && var.truefoundry_aurora_vpc_peering_allow_remote_dns_resolution ? 1 : 0
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.secondary[0].id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

##################################################################################
## Routes (one per supplied route table ID). If the user leaves the lists empty,
## the peering connection is still created but no routes are added — useful when
## routes are managed elsewhere (e.g. a network module).
##################################################################################

resource "aws_route" "primary_to_dr" {
  for_each                  = local.vpc_peering_enabled ? toset(var.truefoundry_aurora_vpc_peering_primary_route_table_ids) : toset([])
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.peering_secondary[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
}

resource "aws_route" "dr_to_primary" {
  for_each                  = local.vpc_peering_enabled ? toset(var.truefoundry_aurora_vpc_peering_dr_route_table_ids) : toset([])
  provider                  = aws.secondary
  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.peering_primary[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_dr[0].id
}

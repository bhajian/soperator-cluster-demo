# ──────────────────────────────────────────────────────────────────────────────
# Use the existing project default subnet.
#
# Why not a new VPC?
#   Nebius tracks private IPv4 allocations globally across the project.
#   A custom CIDR subnet (e.g. 10.0.0.0/16) conflicts with the default
#   subnet's pool (10.0.0.0/13) even when placed in a separate VPC network,
#   causing all internal-LB IP allocation attempts to fail with
#   "Unable to allocate private ipv4 cidr /32 from the pool".
#   The default subnet has routing and NAT pre-configured by Nebius.
#
# Subnet: default-subnet-zyklxvfo  (vpcsubnet-e00dx4kb98s92h4w4w)
# Network: vpcnetwork-e00s8te77d2mesrpgh  |  CIDR: 10.0.0.0/13
# ──────────────────────────────────────────────────────────────────────────────

data "nebius_vpc_v1_subnet" "this" {
  id = "vpcsubnet-e00dx4kb98s92h4w4w"
}

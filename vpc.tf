# ──────────────────────────────────────────────────────────────────────────────
# New VPC for behnam-cluster
# These resources replace the vpc_subnet_id variable that the example reads from
# an environment variable. Terraform creates the network and subnet on first apply
# so no pre-existing subnet is required.
# ──────────────────────────────────────────────────────────────────────────────

resource "nebius_vpc_v1_network" "this" {
  parent_id = data.nebius_iam_v1_project.this.id
  name      = "behnam-cluster-vpc"
}

resource "nebius_vpc_v1_subnet" "this" {
  parent_id  = data.nebius_iam_v1_project.this.id
  network_id = nebius_vpc_v1_network.this.id
  name       = "behnam-cluster-subnet"

  ipv4_private_pools = {
    pools = [{
      cidrs = [{ cidr = "10.0.0.0/16" }]
    }]
  }
}

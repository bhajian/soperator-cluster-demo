#----------------------------------------------------------------------------------------------------------------------#
#                                                                                                                      #
#                                              Terraform - behnam-cluster values                                       #
#                                                                                                                      #
#----------------------------------------------------------------------------------------------------------------------#

# Name used for K8s / Slurm cluster naming (e.g. "soperator-behnam").
company_name = "behnam"

# Demo / non-production cluster — skips the IAM MR URL requirement.
production = false

# Not required when production = false.
iam_merge_request_url = ""

#----------------------------------------------------------------------------------------------------------------------#
#                                                     Infrastructure                                                   #
#----------------------------------------------------------------------------------------------------------------------#
# region Infrastructure

#----------------------------------------------------------------------------------------------------------------------#
#                                                        Storage                                                       #
#----------------------------------------------------------------------------------------------------------------------#
# region Storage

# Controller spool — small spec, created by Terraform.
controller_state_on_filestore = false

filestore_controller_spool = {
  spec = {
    size_gibibytes       = 128
    block_size_kibibytes = 4
    forbid_deletion      = false
  }
}

# ── Jail root filesystem (pre-created, 500 GiB SSD) ──────────────────────────
# behnam-demo-jail-root  →  computefilesystem-e00xzx35xcg58t052h
filestore_jail = {
  existing = {
    id = "computefilesystem-e00xzx35xcg58t052h"
  }
}

# ── Jail submount / data filesystem (pre-created, 500 GiB SSD) ───────────────
# behnam-demo-jail-data  →  computefilesystem-e00bp43xrhxrdakq11
filestore_jail_submounts = [{
  name       = "data"
  mount_path = "/mnt/data"
  existing = {
    id = "computefilesystem-e00bp43xrhxrdakq11"
  }
}]

# Accounting filesystem — created by Terraform.
filestore_accounting = {
  spec = {
    size_gibibytes       = 128
    block_size_kibibytes = 4
    forbid_deletion      = false
  }
}

# endregion Storage

# region nfs-server

# In-K8s NFS for /home.
nfs_in_k8s = {
  enabled         = true
  version         = "1.2.0"
  use_stable_repo = true
  size_gibibytes  = 930
  disk_type       = "NETWORK_SSD_IO_M3"
  filesystem_type = "ext4"
  threads         = 32
}

# endregion nfs-server

#----------------------------------------------------------------------------------------------------------------------#
#                                                         Slurm                                                        #
#----------------------------------------------------------------------------------------------------------------------#
# region Slurm

slurm_operator_version = "4.1.7"
slurm_operator_stable  = true

slurm_nodesets_partitions = [
  {
    name               = "main"
    is_all             = true
    slurm_nodeset_refs = []
    config             = "Default=YES PriorityTier=10 PreemptMode=OFF MaxTime=INFINITE State=UP OverSubscribe=YES"
  },
  {
    name               = "hidden"
    is_all             = true
    slurm_nodeset_refs = []
    config             = "Default=NO PriorityTier=10 PreemptMode=OFF Hidden=YES MaxTime=INFINITE State=UP OverSubscribe=YES"
  },
]

slurm_partition_config_type = "default"

#----------------------------------------------------------------------------------------------------------------------#
#                                                         Nodes                                                        #
#----------------------------------------------------------------------------------------------------------------------#
# region Nodes

slurm_nodeset_system = {
  min_size = 3
  max_size = 9
  resource = {
    platform = "cpu-d3"
    preset   = "8vcpu-32gb"
  }
  boot_disk = {
    type                 = "NETWORK_SSD"
    size_gibibytes       = 192
    block_size_kibibytes = 4
  }
}

slurm_nodeset_controller = {
  size = 1
  resource = {
    platform = "cpu-d3"
    preset   = "16vcpu-64gb"
  }
  boot_disk = {
    type                 = "NETWORK_SSD"
    size_gibibytes       = 256
    block_size_kibibytes = 4
  }
}

slurm_nodeset_workers = [
  # ── CPU worker — 1 node for demo/scheduling tests (no GPU fabric needed) ────
  {
    name = "worker"
    size = 1
    autoscaling = {
      enabled  = false
      min_size = null
    }
    resource = {
      platform = "cpu-d3"
      preset   = "16vcpu-64gb"
    }
    boot_disk = {
      type                 = "NETWORK_SSD"
      size_gibibytes       = 512
      block_size_kibibytes = 4
    }
    gpu_cluster                              = null
    preemptible                              = null
    features                                 = null
    create_partition                         = null
    ephemeral_nodes                          = false
    initial_number_ephemeral_nodes           = 0
    persistent_volume_claim_retention_policy = {
      when_deleted = "Delete"
      when_scaled  = "Delete"
    }
    node_local_jail_submounts = []
    node_local_image_disk = {
      enabled = false
    }
  },

  # ── H200 NVLink SXM — 2 preemptible nodes, fabric-7, eu-north1 ─────────────
  # 8 GPU · 128 vCPU · 1600 GiB RAM  |  GPU mem: 141 GB  |  medium launch chance
  {
    name = "worker-h200"
    size = 2
    autoscaling = {
      enabled  = false
      min_size = null
    }
    resource = {
      platform = "gpu-h200-sxm"
      preset   = "8gpu-128vcpu-1600gb"
    }
    boot_disk = {
      type                 = "NETWORK_SSD"
      size_gibibytes       = 512
      block_size_kibibytes = 4
    }
    gpu_cluster = {
      infiniband_fabric = "fabric-7"
    }
    preemptible                              = {}   # preemptible (spot) instances
    features                                 = null
    create_partition                         = null
    ephemeral_nodes                          = false
    initial_number_ephemeral_nodes           = 0
    persistent_volume_claim_retention_policy = {
      when_deleted = "Delete"
      when_scaled  = "Delete"
    }
    node_local_jail_submounts = []
    node_local_image_disk = {
      enabled = true
      spec = {
        size_gibibytes  = 930
        filesystem_type = "ext4"
        disk_type       = "NETWORK_SSD_IO_M3"
      }
    }
  },
]

use_preinstalled_gpu_drivers = true

slurm_nodeset_login = {
  size = 1
  resource = {
    platform = "cpu-d3"
    preset   = "16vcpu-64gb"
  }
  boot_disk = {
    type                 = "NETWORK_SSD"
    size_gibibytes       = 256
    block_size_kibibytes = 4
  }
}

slurm_nodeset_accounting = {
  resource = {
    platform = "cpu-d3"
    preset   = "8vcpu-32gb"
  }
  boot_disk = {
    type                 = "NETWORK_SSD"
    size_gibibytes       = 128
    block_size_kibibytes = 4
  }
}

slurm_nodeset_nfs = {
  size = 1
  resource = {
    platform = "cpu-d3"
    preset   = "32vcpu-128gb"
  }
  boot_disk = {
    type                 = "NETWORK_SSD"
    size_gibibytes       = 128
    block_size_kibibytes = 4
  }
}

# endregion Nodes

#----------------------------------------------------------------------------------------------------------------------#
#                                                         Login                                                        #
#----------------------------------------------------------------------------------------------------------------------#
slurm_login_public_ip   = true
tailscale_enabled       = false
slurm_sssd_enabled      = false

slurm_sssd_conf_secret_ref_name        = ""
slurm_sssd_ldap_ca_config_map_ref_name = ""

# TODO: replace with your SSH public key before running terraform apply
slurm_login_ssh_root_public_keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItv2zTURVykDX8p1b/KmRnRZqE1vvHTYpV1vkQtGz6k behnam.hajian@nebius.com",
]

#----------------------------------------------------------------------------------------------------------------------#
#                                                       Exporter                                                       #
#----------------------------------------------------------------------------------------------------------------------#
slurm_exporter_enabled = true

#----------------------------------------------------------------------------------------------------------------------#
#                                                     ActiveChecks                                                     #
#----------------------------------------------------------------------------------------------------------------------#
# "dev" skips long-running checks — suitable for a demo cluster.
active_checks_scope = "dev"

#----------------------------------------------------------------------------------------------------------------------#
#                                                        Config                                                        #
#----------------------------------------------------------------------------------------------------------------------#
slurm_shared_memory_size_gibibytes = 64
slurm_topology_block_size          = null
maintenance_ignore_node_groups     = ["controller", "nfs"]

#----------------------------------------------------------------------------------------------------------------------#
#                                                       Telemetry                                                      #
#----------------------------------------------------------------------------------------------------------------------#
telemetry_enabled        = true
dcgm_job_mapping_enabled = true
public_o11y_enabled      = true

soperator_notifier = {
  enabled = false
}

#----------------------------------------------------------------------------------------------------------------------#
#                                                      Accounting                                                      #
#----------------------------------------------------------------------------------------------------------------------#
accounting_enabled = true

#----------------------------------------------------------------------------------------------------------------------#
#                                                       Backups                                                        #
#----------------------------------------------------------------------------------------------------------------------#
# Both jail filesystems are 500 GiB (< 12 TiB) so backups are on by default.
backups_enabled        = "auto"
backups_password       = "change-me-before-deploy"
backups_schedule       = "@daily-random"
backups_prune_schedule = "@daily-random"
backups_retention = {
  keepDaily = 7
}
cleanup_bucket_on_destroy = false

#----------------------------------------------------------------------------------------------------------------------#
#                                                     Kubernetes                                                       #
#----------------------------------------------------------------------------------------------------------------------#
k8s_version = "1.33"

nvidia_config_lines = [
  "options nvidia NVreg_RestrictProfilingToAdminUsers=0",
  "options nvidia NVreg_EnableStreamMemOPs=1",
  "options nvidia NVreg_RegistryDwords=\"PeerMappingOverride=1;\"",
]

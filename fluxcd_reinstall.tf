# ──────────────────────────────────────────────────────────────────────────────
# FluxCD reinstall guard
#
# Problem: modules/fluxcd uses triggers_replace = { first_run = "true" }, a
# static value that never changes. FluxCD is therefore installed exactly once.
# If the Kubernetes cluster is destroyed and recreated, the flux-system namespace
# and all FluxCD deployments are gone, but Terraform state still shows
# module.fluxcd resources as "applied". Terraform skips them, module.slurm
# waits forever for the HelmRelease CRD, and the apply stalls.
#
# Fix: this resource fires whenever module.k8s.cluster_id changes, i.e. every
# time the K8s cluster is (re)created. It runs the same idempotent kubectl
# commands as the upstream module. module.slurm depends_on this resource
# (see main.tf) so Slurm cannot start until FluxCD is healthy.
# ──────────────────────────────────────────────────────────────────────────────

resource "terraform_data" "fluxcd_reinstall" {
  depends_on = [
    module.k8s,
    module.fluxcd, # let module.fluxcd run first (first-time install); this is the catch-all for re-runs
  ]

  # Trigger on the cluster ID — changes whenever the cluster is recreated.
  triggers_replace = {
    cluster_id = module.k8s.cluster_id
  }

  # Step 1: ensure flux-system namespace exists (idempotent via dry-run→apply).
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = join(" ", [
      "${path.module}/../../modules/scripts/retry.sh", "--", "bash", "-c",
      "'kubectl create namespace flux-system --context ${module.k8s.cluster_context} --dry-run=client -o yaml",
      "| kubectl apply --context ${module.k8s.cluster_context} -f -'",
    ])
  }

  # Step 2: apply FluxCD manifests (idempotent kubectl apply).
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = join(
      " ",
      [
        "${path.module}/../../modules/scripts/retry.sh", "--",
        "kubectl", "--context", module.k8s.cluster_context,
        "apply", "-f", "https://github.com/fluxcd/flux2/releases/download/v2.7.4/install.yaml",
      ]
    )
  }
}

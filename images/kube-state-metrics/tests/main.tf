terraform {
  required_providers {
    oci = { source = "chainguard-dev/oci" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_exec_test" "run" {
  digest      = var.digest
  script      = "./helm.sh"
  working_dir = path.module

  # Split the digest ref into just its digest.
  # Given var.digest = "cgr.dev/chainguard/kube-state-metrics@sha256:abc123"
  # IMAGE_SHA will be set to "sha256:abc123"
  env {
    name  = "IMAGE_SHA"
    value = element(split("@", var.digest), 1)
  }
}


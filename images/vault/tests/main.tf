terraform {
  required_providers {
    oci    = { source = "chainguard-dev/oci" }
    random = { source = "hashicorp/random" }
    helm   = { source = "hashicorp/helm" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_exec_test" "version" {
  digest = var.digest
  script = "docker run --cap-add IPC_LOCK --rm $${IMAGE_NAME} --version"
}

data "oci_exec_test" "run" {
  digest      = var.digest
  script      = "./runs.sh"
  working_dir = path.module
}

data "oci_exec_test" "helm" {
  digest      = var.digest
  script      = "./helm.sh"
  working_dir = path.module

  # Split the digest ref into repository and digest. The helm chart expects a
  # tag, but it just appends it to the repository again, so we just specify a
  # dummy tag and the digest to test.
  env {
    name  = "IMAGE_TAG"
    value = "unused@${element(split("@", data.oci_exec_test.version.tested_ref), 1)}"
  }
  env {
    name  = "IMAGE_REPOSITORY"
    value = element(split("@", data.oci_exec_test.version.tested_ref), 0)
  }
}

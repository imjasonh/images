terraform {
  required_providers {
    oci    = { source = "chainguard-dev/oci" }
    random = { source = "hashicorp/random" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_exec_test" "version" {
  digest = var.digest
  script = "docker run --rm $${IMAGE_NAME} --version"
}

resource "random_pet" "random" {}

data "oci_exec_test" "e2e" {
  digest      = var.digest
  script      = "./e2e.sh"
  working_dir = path.module

  env {
    name  = "NAMESPACE"
    value = random_pet.random.id
  }
}

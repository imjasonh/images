terraform {
  required_providers {
    oci = { source = "chainguard-dev/oci" }
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_exec_test" "help" {
  digest = var.digest
  script = "${path.module}/01-help.sh"
}

data "oci_exec_test" "build_website" {
  digest = var.digest
  script = "${path.module}/02-build-website.sh"
}

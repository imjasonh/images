terraform {
  required_providers {
    oci    = { source = "chainguard-dev/oci" }
    random = { source = "hashicorp/random" }
    helm   = { source = "hashicorp/helm" }
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

variable "digest" {
  description = "The image digest to run tests over."
}

data "oci_exec_test" "version" {
  digest      = var.digest
  script      = "./01-version.sh"
  working_dir = path.module
}

data "oci_exec_test" "nslookup" {
  digest      = var.digest
  script      = "./02-nslookup-with-Corefile.sh"
  working_dir = path.module
}

resource "random_pet" "suffix" {}

resource "helm_release" "coredns" {
  name = "coredns-${random_pet.suffix.id}"

  repository = "https://coredns.github.io/helm"
  chart      = "coredns"

  namespace        = "coredns-${random_pet.suffix.id}"
  create_namespace = true

  # Split the digest ref into repository and digest. The helm chart expects a
  # tag, but it just appends it to the repository again, so we just specify a
  # dummy tag and the digest to test.
  set {
    name  = "image.tag"
    value = "unused@${element(split("@", data.oci_exec_test.version.tested_ref), 1)}"
  }
  set {
    name  = "image.repository"
    value = element(split("@", data.oci_exec_test.version.tested_ref), 0)
  }
  set {
    name  = "isClusterService"
    value = "false"
  }
}

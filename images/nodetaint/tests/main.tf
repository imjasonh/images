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

resource "random_pet" "suffix" {}

resource "helm_release" "nodetaint" {
  name = "nodetaint-${random_pet.suffix.id}"

  repository = "https://raw.githubusercontent.com/wish/nodetaint/master/chart/"
  chart      = "nodetaint"

  namespace        = "nodetaint-${random_pet.suffix.id}"
  create_namespace = true

  # Split the digest ref into repository and digest. The helm chart expects a
  # tag, but it just appends it to the repository again, so we just specify a
  # dummy tag and the digest to test.
  set {
    name  = "image.tag"
    value = "unused@${element(split("@", var.digest), 1)}"
  }
  set {
    name  = "image.repository"
    value = element(split("@", var.digest), 0)
  }
  set {
    name  = "image.registry"
    value = ""
  }
}

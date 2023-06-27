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

locals {
  full_repository = element(split("@", var.digest), 0)                    // cgr.dev/chainguard/weaviate
  registry        = element(split("/", local.full_repository), 0)         // cgr.dev
  parts           = split("/", local.full_repository)                     // ['cgr.dev', 'chainguard', 'weaviate']
  repository      = join("/", slice(local.parts, 1, length(local.parts))) // chainguard/weaviate
}

resource "random_pet" "suffix" {}

resource "helm_release" "weaviate" {
  name = "weaviate-${random_pet.suffix.id}"

  repository = "https://weaviate.github.io/weaviate-helm"
  chart      = "weaviate"

  namespace        = "weaviate-${random_pet.suffix.id}"
  create_namespace = true

  # Split the digest ref into repository and digest. The helm chart expects a
  # tag, but it just appends it to the repository again, so we just specify a
  # dummy tag and the digest to test.
  set {
    name  = "image.tag"
    value = "unused@${element(split("@", var.digest), 1)}"
  }
  set {
    name  = "image.repo"
    value = local.repository
  }
  set {
    name  = "image.registry"
    value = local.registry
  }
}

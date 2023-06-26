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

data "oci_exec_test" "run" {
  digest = var.digest
  script = "docker run --rm $${IMAGE_NAME} --help"
}

resource "random_string" "random" {
  length  = 6
  upper   = false
  special = false
}

resource "helm_release" "gatekeeper" {
  name = "gatekeeper-${random_string.random.result}"

  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"

  namespace        = "gatekeeper-${random_string.random.result}"
  create_namespace = true

  # Split the digest ref into repository and digest. The helm chart expects a
  # tag, but it just appends it to the repository again, so we just specify a
  # dummy tag and the digest to test.
  set {
    name  = "image.tag"
    value = "unused@${element(split("@", data.oci_exec_test.run.tested_ref), 1)}"
  }
  set {
    name  = "image.repository"
    value = element(split("@", data.oci_exec_test.run.tested_ref), 0)
  }
  # Unfortunately the helm chart uses the same 'release' value as the tag for multiple images in the chart
  # Re-overriding it with the preInstall.crdRepository.image.tag value works, but requires us to hardcode some other
  # image names.
  set {
    name  = "preInstall.crdRepository.image.tag"
    value = "v3.13.0-beta.1"
  }
  set {
    name  = "preInstall.crdRepository.image.repository"
    value = "openpolicyagent/gatekeeper-crds"
  }
}


/*
TODO: fails with
from server for: "crds/provider-customresourcedefinition.yaml": customresourcedefinitions.apiextensions.k8s.io "providers.externaldata.gatekeeper.sh" is forbidden: User "system:serviceaccount:gatekeeper-436gxj:gatekeeper-admin-upgrade-crds" cannot get resource "customresourcedefinitions" in API group "apiextensions.k8s.io" at the cluster scope
*/

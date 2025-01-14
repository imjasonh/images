terraform {
  required_providers {
    oci  = { source = "chainguard-dev/oci" }
    helm = { source = "hashicorp/helm" }
  }
}

variable "digests" {
  description = "The image digest to run tests over."
  type = object({
    proxy    = string
    pilot    = string
    operator = string
  })
}

variable "namespace" {
  description = "The namespace to install Istio in."
}

data "oci_exec_test" "proxy-version" {
  digest = var.digests.proxy
  script = "docker run --rm $IMAGE_NAME --version"
}

data "oci_exec_test" "pilot-version" {
  digest = var.digests.pilot
  script = "docker run --rm $IMAGE_NAME --version"
}

data "oci_exec_test" "operator-version" {
  digest = var.digests.operator
  script = "docker run --rm $IMAGE_NAME version"
}

data "oci_string" "operator-ref" { input = var.digests.operator }
data "oci_string" "proxy-ref" { input = var.digests.proxy }

resource "helm_release" "operator" {
  name             = "operator"
  namespace        = local.namespace
  create_namespace = true
  # there's no official helm chart for the istio operator
  repository = "https://stevehipwell.github.io/helm-charts/"
  chart      = "istio-operator"

  values = [jsonencode({
    image = {
      repository = data.oci_string.operator-ref.registry_repo
      tag        = data.oci_string.operator-ref.pseudo_tag
    }
  })]
}

resource "random_pet" "suffix" {}

locals {
  namespace = "istio-system-${random_pet.suffix.id}"
}
resource "helm_release" "base" {
  name             = "${local.namespace}-base"
  namespace        = local.namespace
  create_namespace = true
  repository       = "https://istio-release.storage.googleapis.com/charts/"
  chart            = "base"
  replace          = true # Allow reinstallation - as CRDs are not reinstalled anyway.
  values = [jsonencode({
    global = {
      istioNamespace = local.namespace
    }
  })]
}

resource "helm_release" "istiod" {
  depends_on       = [helm_release.base]
  name             = "${local.namespace}-istiod"
  namespace        = local.namespace
  create_namespace = true
  repository       = "https://istio-release.storage.googleapis.com/charts/"
  chart            = "istiod"
  values = [jsonencode({
    # Set the revision so that only namespace with istio.io/rev=local.namespace
    # will be managed.
    revision = local.namespace
    pilot = {
      image = var.digests.pilot
    }
    global = {
      istioNamespace = local.namespace
      # We have to trim the suffix and specify it in `image`, because this
      # Helm chart does not like slashes in the image name.
      hub = replace(data.oci_string.proxy-ref.registry_repo, "/istio-proxy", "")
      tag = data.oci_string.proxy-ref.pseudo_tag
      proxy = {
        image = "istio-proxy"
      }
      proxy-init = {
        image = "istio_proxy"
      }
    }
  })]
}

resource "helm_release" "gateway" {
  depends_on       = [helm_release.istiod]
  name             = "${local.namespace}-gateway"
  namespace        = local.namespace
  create_namespace = true
  repository       = "https://istio-release.storage.googleapis.com/charts/"
  chart            = "gateway"
  values = [jsonencode({
    # Set the revision so that only namespace with istio.io/rev=local.namespace
    # will be managed.
    revision = local.namespace
    service = {
      type = "ClusterIP"
    }
    global = {
      istioNamespace = local.namespace
      # We have to trim the suffix and specify it in `image`, because this
      # Helm chart does not like slashes in the image name.
      hub = replace(data.oci_string.proxy-ref.registry_repo, "/istio-proxy", "")
      tag = data.oci_string.proxy-ref.pseudo_tag
      proxy = {
        image = "istio-proxy"
      }
      proxy-init = {
        image = "istio_proxy"
      }
    }
  })]
}

# Test the sidecar injection.
data "oci_exec_test" "sidecar-injection-works" {
  depends_on = [helm_release.istiod]

  script = "${path.module}/test-injection.sh"
  digest = var.digests.proxy

  env {
    name  = "ISTIO_NAMESPACE"
    value = local.namespace
  }
}

# Test that simple VirtualService/Gateway is working.
data "oci_exec_test" "gateway" {
  depends_on = [helm_release.gateway]

  script = "${path.module}/test-gateway.sh"
  digest = var.digests.proxy

  env {
    name  = "ISTIO_NAMESPACE"
    value = local.namespace
  }
}

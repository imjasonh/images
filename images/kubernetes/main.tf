terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
  }
}

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

module "tagger" {
  source = "../../tflib/tagger"

  depends_on = [module.pause-test-latest]

  tags = merge(
    { for t in toset(concat(["latest"], module.pause-version-tags.tag_list)) : t => module.pause-latest.image_ref },
    { for t in toset(concat(["latest"], module.kube-apiserver-128-version-tags.tag_list)) : t => module.kube-apiserver-latest.image_ref },
  )
}

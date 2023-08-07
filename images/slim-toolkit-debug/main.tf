terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
  }
}

variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

module "slim-toolkit-debug-latest" {
  source = "../../tflib/publisher"

  name              = basename(path.module)
  target_repository = var.target_repository
  config            = file("${path.module}/configs/latest.apko.yaml")
}

module "version-tags" {
  source  = "../../tflib/version-tags"
  package = "bash"
  config  = module.slim-toolkit-debug-latest.config
}

module "test-slim-toolkit-debug-latest" {
  source = "./tests"
  digest = module.slim-toolkit-debug-latest.image_ref
}

module "tagger" {
  source = "../../tflib/tagger"

  depends_on = [module.test-slim-toolkit-debug-latest]

  tags = merge(
    { for t in toset(concat(["latest"], module.version-tags.tag_list)) : t => module.slim-toolkit-debug-latest.image_ref },
  )
}

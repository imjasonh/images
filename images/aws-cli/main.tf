variable "target_repository" {
  description = "The docker repo into which the image and attestations should be published."
}

module "latest" {
  source            = "../../tflib/publisher"
  name              = basename(path.module)
  target_repository = var.target_repository
  config            = file("${path.module}/configs/latest.apko.yaml")
  build-dev         = true
}

module "test-latest" {
  source = "./tests"
  digest = module.latest.image_ref
}

resource "oci_tag" "latest" {
  depends_on = [module.test-latest]
  digest_ref = module.latest.image_ref
  tag        = "latest"
}

resource "oci_tag" "latest-dev" {
  depends_on = [module.test-latest]
  digest_ref = module.latest.dev_ref
  tag        = "latest-dev"
}

// TODO: Remove this.
module "version-tags" {
  source  = "../../tflib/version-tags"
  package = "aws-cli"
  config  = module.latest.config
}

// TODO: Remove this.
module "tagger" {
  source = "../../tflib/tagger"

  depends_on = [module.test-latest]

  tags = merge(
    { for t in module.version-tags.tag_list : t => module.latest.image_ref },
    { for t in module.version-tags.tag_list : "${t}-dev" => module.latest.dev_ref },
  )
}

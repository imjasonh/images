module "pause-latest" {
  source = "../../tflib/publisher"

  name              = basename(path.module)
  target_repository = var.target_repository
  config            = file("${path.module}/configs/pause.apko.yaml")
}

module "pause-version-tags" {
  source  = "../../tflib/version-tags"
  package = "kubernetes-pause-3.9"
  config  = module.pause-latest.config
}

module "pause-test-latest" {
  source = "./tests"
  digest = module.pause-latest.image_ref
}

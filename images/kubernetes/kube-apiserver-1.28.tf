module "kube-apiserver-latest" {
  source = "../../tflib/publisher"

  name              = basename(path.module)
  target_repository = var.target_repository
  config            = file("${path.module}/configs/kube-apiserver.apko.yaml")
}

module "kube-apiserver-128-version-tags" {
  source  = "../../tflib/version-tags"
  package = "kube-apiserver-1.28"
  config  = module.kube-apiserver-latest.config
}

# TODO: tests.

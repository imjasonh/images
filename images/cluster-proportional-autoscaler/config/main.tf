variable "extra_packages" {
  description = "Additional packages to install."
  type        = list(string)
  default     = ["cluster-proportional-autoscaler"]
}

module "accts" { source = "../../../tflib/accts" }

output "config" {
  value = jsonencode({
    contents = {
      packages = concat([
        "bash",
        "busybox",
        "curl",
      ], var.extra_packages)
    }
    accounts = module.accts.block
    entrypoint = {
      command = "/usr/bin/cluster-proportional-autoscaler"
    }
  })
}

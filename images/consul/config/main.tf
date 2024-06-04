terraform {
  required_providers {
    apko = { source = "chainguard-dev/apko" }
  }
}

variable "extra_packages" {
  description = "The additional packages to install (e.g. consul<1.17)."
  default     = []
}

variable "extra_repositories" {
  description = "The additional repositories to install from."
  type        = list(string)
  default     = []
}

variable "extra_keyring" {
  description = "The additional keys to use."
  type        = list(string)
  default     = []
}

locals { base_config = yamldecode(file("${path.module}/template.apko.yaml")) }

data "apko_config" "this" {
  config_contents = yamlencode(merge(
    local.base_config,
    {
      // Allow injecting extra repositories and keyrings.
      contents = {
        repositories = var.extra_repositories
        keyring      = var.extra_keyring
        packages     = local.base_config.contents.packages
      }
    },
  ))
  extra_packages = var.extra_packages
}

output "config" {
  value = jsonencode(data.apko_config.this.config)
}

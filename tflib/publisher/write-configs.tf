locals {
  enable  = false // Enables writing pre- and post-resolved configs to disk.
  decoded = yamldecode(var.config)
}

resource "null_resource" "pre-resolve" {
  count = local.enable ? 1 : 0

  provisioner "local-exec" {
    command = <<EOC
cat <<EOF > ${path.root}/${basename(var.target_repository)}.${substr(md5(var.config), 0, 6)}.apko.json
${jsonencode(merge(
    local.decoded,
    {
      contents = {
        packages = tolist(toset(concat(local.decoded["contents"]["packages"], var.extra_packages)))
      }
    },
))}
EOF
EOC
}
}

resource "null_resource" "pre-resolve-dev" {
  count = local.build-dev && local.enable ? 1 : 0
  provisioner "local-exec" {
    command = <<EOC
cat <<EOF > ${path.root}/${basename(var.target_repository)}.${substr(md5(var.config), 0, 6)}.dev.apko.json
${jsonencode(merge(
    local.decoded,
    {
      contents = {
        packages = tolist(toset(concat(local.decoded["contents"]["packages"], var.extra_packages, local.default_dev_packages, var.extra_dev_packages)))
      }
    },
))}
EOF
EOC
}
}

resource "null_resource" "post-resolve" {
  count = local.enable ? 1 : 0

  provisioner "local-exec" {
    command = <<EOC
cat <<EOF > ${path.root}/${basename(var.target_repository)}.${substr(md5(var.config), 0, 6)}.post.apko.json
${jsonencode(module.this.config)}
EOF
EOC
  }
}

resource "null_resource" "post-resolve-dev" {
  count = local.build-dev && local.enable ? 1 : 0

  provisioner "local-exec" {
    command = <<EOC
cat <<EOF > ${path.root}/${basename(var.target_repository)}.${substr(md5(var.config), 0, 6)}.post.dev.apko.json
${jsonencode(module.this-dev[0].config)}
EOF
EOC
  }
}

# DO NOT EDIT - this file is autogenerated by tfgen

output "summary" {
  value = merge(
    {
      basename(path.module) = {
        "ref"    = module.busl.image_ref
        "config" = module.busl.config
        "tags"   = ["latest"]
      }
    },
    {
      basename(path.module) = {
        "ref"    = module.mpl.image_ref
        "config" = module.mpl.config
        "tags"   = ["each.key"]
      }
  })
}


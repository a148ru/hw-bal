data template_file "cloudinit" {
  template = file("./cloud-config.yml")

  vars = {
    ssh_public_key = local.ssh_key
    link_image = "http://${yandex_storage_bucket.bucket.website_endpoint}/${yandex_storage_object.test-object.key}"
  }
}
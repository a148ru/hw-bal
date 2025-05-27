
resource "yandex_storage_bucket" "bucket" {
  bucket = var.bucket.name
  folder_id = var.folder_id
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key  = yandex_iam_service_account_static_access_key.sa-static-key.secret_key

  website {
    index_document = var.bucket.index_document
    error_document = var.bucket.error_document
  }
  max_size = var.bucket.size

  anonymous_access_flags {
    read = true
    list = true
  }
  depends_on = [ yandex_resourcemanager_folder_iam_member.bucket-sa ]
}

# Создание сервисного аккаунта

resource "yandex_iam_service_account" "netology-sa" {
  name = var.sa.name
  depends_on = [ yandex_vpc_subnet.subnet ]
}

# Назначение ролей сервисному аккаунту

resource "yandex_resourcemanager_folder_iam_member" "bucket-sa" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.netology-sa.id}"
  depends_on = [ yandex_iam_service_account_static_access_key.sa-static-key ]
}

resource "yandex_resourcemanager_folder_iam_member" "compute-editor" {
  folder_id = var.folder_id
  role      = "compute.editor"
  member    = "serviceAccount:${yandex_iam_service_account.netology-sa.id}"
  depends_on = [ yandex_iam_service_account_static_access_key.sa-static-key ]
}

resource "yandex_resourcemanager_folder_iam_member" "load-balancer-editor" {
  folder_id = var.folder_id
  role      = "load-balancer.editor"
  member    = "serviceAccount:${yandex_iam_service_account.netology-sa.id}"
  depends_on = [ yandex_iam_service_account_static_access_key.sa-static-key ]
}

# Создание статического ключа доступа

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.netology-sa.id
  description        = "static access key"
}

# Создание объекта

resource "yandex_storage_object" "test-object" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = var.bucket.name
  key        = var.image.key
  source     = var.image.source
  depends_on = [ yandex_resourcemanager_folder_iam_member.bucket-sa, yandex_storage_bucket.bucket, yandex_iam_service_account_static_access_key.sa-static-key ]
}


# Группа ВМ
resource "yandex_compute_instance_group" "ig-1" {
  name                = var.vm_res.name_group
  folder_id           =  var.folder_id
  service_account_id  = "${yandex_iam_service_account.netology-sa.id}"
  instance_template {
    platform_id = var.vm_res.platform_id
    resources {
      memory = var.vm_res.memory
      cores  = var.vm_res.vcpu
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.vm_res.image_id
      }
    }

    network_interface {
      network_id         = "${yandex_vpc_network.network.id}"
      subnet_ids         = ["${yandex_vpc_subnet.subnet.id}"]
      # security_group_ids = ["<список_идентификаторов_групп_безопасности>"]
    }

    metadata    = {
      user-data = data.template_file.cloudinit.rendered
  }
  }

  scale_policy {
    fixed_scale {
      size = var.ig-params.scale_size
    }
  }

  allocation_policy {
    zones = ["${var.default_zone}"]
  }

  deploy_policy {
    max_unavailable = var.ig-params.deploy_policy_unavailable
    max_expansion   = var.ig-params.deploy_policy_expansion
  }

  load_balancer {
    target_group_name        = var.ig-params.target_group_name
    target_group_description = "Целевая группа Network Load Balancer"
  }
  depends_on = [ yandex_resourcemanager_folder_iam_member.load-balancer-editor,yandex_resourcemanager_folder_iam_member.compute-editor, yandex_vpc_subnet.subnet ]
}

# сетевой баланс-к
resource "yandex_lb_network_load_balancer" "lb-1" {
  name = var.load_balancer.name

  listener {
    name = var.load_balancer.listener_name
    port = var.load_balancer.listener_port
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.ig-1.load_balancer.0.target_group_id

    healthcheck {
      name = "http"
      http_options {
        port = var.load_balancer.http_healthcheck_port
        path = var.load_balancer.http_healthcheck_path
      }
    }
  }
  depends_on = [ yandex_compute_instance_group.ig-1 ]
}

# Сеть
resource "yandex_vpc_network" "network" {
  name = var.network.name
}
# Подсеть
resource "yandex_vpc_subnet" "subnet" {
  name           = var.subnet.name
  zone           = var.default_zone
  network_id     = "${yandex_vpc_network.network.id}"
  v4_cidr_blocks = var.subnet.v4_cidr
}

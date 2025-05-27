###cloud vars
variable "token" {
  type        = string
  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
}

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-b"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "bucket" {
  type = object({
    name = string,
    size = number,
    index_document = string,
    error_document = string
  })
}

variable "image" {
  type = object({
    key = string,
    source = string
  })
}

variable "vm_res" {
  type = object({
    name_group = string,
    platform_id = string,
    image_id = string,
    memory = number,
    vcpu = number
  })
}
variable "ig-params" {
  type = object({
    scale_size = number,
    deploy_policy_unavailable = number,
    deploy_policy_expansion = number,
    target_group_name = string 
  })
}

variable "network" {
  type = object({
    name = string
  })
}

variable "subnet" {
  type = object({
    name = string,
    v4_cidr = list(string)
  })
}

variable "load_balancer" {
  type = object({
    name = string,
    listener_name = string,
    listener_port = number,
    http_healthcheck_port = number
    http_healthcheck_path = string
  })
}

variable "sa" {
  type = object({
    name = string
  })
}
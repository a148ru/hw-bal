output "lb-link" {
  value = "http://${[for y in [for i in yandex_lb_network_load_balancer.lb-1.listener : i][0].external_address_spec : y][0].address}"
}